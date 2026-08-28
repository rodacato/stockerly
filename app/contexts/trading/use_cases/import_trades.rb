module Trading
  module UseCases
    # Replays a batch of already-executed trades into the portfolio.
    #
    # Deliberately NOT fifty calls to ExecuteTrade. An import has different
    # invariants: it is ordered, it is idempotent, and its side effects belong
    # to the batch rather than to each row. Running it row-by-row through
    # ExecuteTrade fires three handlers per trade and makes the backdated
    # snapshot handler rebuild the same range once per trade.
    #
    # Every failure is batch-level and reports every offending row at once —
    # stopping on the first bad row of fifty tells you almost nothing.
    class ImportTrades < ApplicationUseCase
      # The reference currency is fixed, not the user's current preference:
      # fx_rate_at_execution outlives the preference, and a rate stored
      # relative to a setting is wrong the moment the setting changes.
      REFERENCE_CURRENCY = "MXN".freeze

      def call(user:, rows:, dry_run: true)
        portfolio = user.portfolio
        return Failure([ :not_found, "Portfolio not found" ]) unless portfolio

        parsed = yield validate_rows(rows)
        assets = yield resolve_assets(parsed)
        rates  = yield resolve_fx_rates(parsed)

        fresh, skipped = partition_already_imported(portfolio, parsed)
        report = build_report(fresh, skipped, dry_run)
        return Success(report) if dry_run

        commit(portfolio, fresh, assets, rates)
        after_commit(portfolio, user, fresh)

        Success(report)
      end

      private

      def validate_rows(rows)
        contract = Trading::Contracts::ImportTradeRowContract.new
        results = rows.each_with_index.map { |row, i| [ i + 1, contract.call(row) ] }
        invalid = results.reject { |_, r| r.success? }

        return Failure([ :invalid_rows, invalid.map { |n, r| { row: n, errors: r.errors.to_h } } ]) if invalid.any?

        Success(results.map { |_, r| r.to_h }.sort_by { |a| a[:executed_at] })
      end

      # Phase 0 refuses rather than inventing catalogue entries: the row carries
      # a symbol and nothing else, so anything created from it would be an asset
      # with no type, exchange or country.
      def resolve_assets(parsed)
        symbols = parsed.map { |r| r[:asset_symbol].upcase }.uniq
        found = Asset.where(symbol: symbols).index_by(&:symbol)
        missing = symbols - found.keys
        return Failure([ :unknown_symbols, missing.sort ]) if missing.any?

        unsupported = found.values.select(&:asset_type_fixed_income?).map(&:symbol)
        return Failure([ :unsupported_asset_type, unsupported.sort ]) if unsupported.any?

        Success(found)
      end

      # Resolved up front for every distinct pair so a missing historical rate
      # fails the batch instead of silently valuing a December trade at today's
      # rate — which is what a plain resolver call would do.
      def resolve_fx_rates(parsed)
        pairs = parsed.map { |r| [ currency_of(r), executed_on(r) ] }.uniq
        rates = {}
        missing = []

        pairs.each do |currency, date|
          rate = currency == REFERENCE_CURRENCY ? BigDecimal(1) : FxRateHistory.rate_on(base: currency, quote: REFERENCE_CURRENCY, date: date)
          rate ? rates[[ currency, date ]] = rate : missing << "#{currency}->#{REFERENCE_CURRENCY} on #{date}"
        end

        missing.any? ? Failure([ :missing_fx_history, missing.sort ]) : Success(rates)
      end

      def partition_already_imported(portfolio, parsed)
        ids = parsed.filter_map { |r| r[:external_id].presence }
        taken = ids.any? ? portfolio.trades.where(external_id: ids).pluck(:external_id).to_set : Set.new

        parsed.partition { |r| r[:external_id].blank? || !taken.include?(r[:external_id]) }
      end

      def commit(portfolio, rows, assets, rates)
        ActiveRecord::Base.transaction do
          rows.group_by { |r| r[:asset_symbol].upcase }.each do |symbol, asset_rows|
            replay_asset(portfolio, assets.fetch(symbol), asset_rows, rates)
          end

          backdate_inception(portfolio, rows)
        end
      end

      def replay_asset(portfolio, asset, rows, rates)
        position = portfolio.positions.find_by(asset: asset, status: :open) ||
                   portfolio.positions.new(asset: asset, shares: 0, avg_cost: rows.first[:price_per_share], status: :open)

        position.opened_at = [ position.opened_at, rows.first[:executed_at] ].compact.map { |t| t.is_a?(String) ? Time.zone.parse(t) : t }.min
        position.save!

        rows.each { |row| create_trade(portfolio, asset, position, row, rates) }

        apply_share_movement(position, rows)
        position.recalculate_avg_cost!
      end

      def create_trade(portfolio, asset, position, row, rates)
        currency = currency_of(row)

        portfolio.trades.create!(
          asset: asset,
          position: position,
          side: row[:side],
          shares: row[:shares],
          price_per_share: row[:price_per_share],
          fee: row[:fee] || 0,
          currency: currency,
          fx_rate_at_execution: rates.fetch([ currency, executed_on(row) ]),
          external_id: row[:external_id].presence,
          executed_at: Time.zone.parse(row[:executed_at])
        )
      end

      def apply_share_movement(position, rows)
        delta = rows.sum { |r| r[:side] == "buy" ? r[:shares] : -r[:shares] }
        remaining = position.shares + delta
        raise ActiveRecord::RecordInvalid, position if remaining.negative?

        if remaining.zero?
          position.update!(shares: remaining, status: :closed, closed_at: Time.current)
        else
          position.update!(shares: remaining)
        end
      end

      # RebuildSnapshots clamps to the portfolio's inception, so a portfolio
      # created after its own trades would silently drop every snapshot before
      # that date.
      def backdate_inception(portfolio, rows)
        earliest = rows.map { |r| executed_on(r) }.min
        return if portfolio.inception_date && portfolio.inception_date <= earliest

        portfolio.update!(inception_date: earliest)
      end

      # Outside the transaction on purpose: a rolled-back import must not leave
      # published events or rewritten snapshots behind.
      def after_commit(portfolio, user, rows)
        return if rows.empty?

        earliest = rows.map { |r| executed_on(r) }.min
        Trading::UseCases::RebuildSnapshots.call(portfolio: portfolio, from: earliest)

        publish(Events::TradesImported.new(
          portfolio_id: portfolio.id,
          user_id: user.id,
          trade_count: rows.size,
          earliest_executed_on: earliest.to_s
        ))
      end

      def build_report(fresh, skipped, dry_run)
        {
          dry_run: dry_run,
          imported: fresh.size,
          skipped: skipped.map { |r| { asset_symbol: r[:asset_symbol], external_id: r[:external_id] } },
          invested: fresh.sum { |r| r[:shares] * r[:price_per_share] },
          symbols: fresh.map { |r| r[:asset_symbol].upcase }.uniq.sort,
          earliest_on: fresh.map { |r| executed_on(r) }.min,
          latest_on: fresh.map { |r| executed_on(r) }.max
        }
      end

      def currency_of(row) = row[:currency].presence || "USD"

      def executed_on(row) = Time.zone.parse(row[:executed_at]).to_date
    end
  end
end
