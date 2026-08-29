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
      # The four values every step below needs. They were threaded as four
      # parameters through five methods; naming the tuple is what that was
      # asking for.
      Batch = Data.define(:portfolio, :rows, :assets, :rates)

      def call(user:, rows:, dry_run: true)
        portfolio = user.portfolio
        return Failure([ :not_found, "Portfolio not found" ]) unless portfolio

        parsed = yield validate_rows(rows)
        assets = yield resolve_assets(parsed)
        rates  = yield resolve_fx_rates(parsed)

        fresh, skipped = partition_already_imported(portfolio, parsed)
        report = build_report(fresh, skipped, dry_run)
        return Success(report) if dry_run

        batch = Batch.new(portfolio: portfolio, rows: fresh, assets: assets, rates: rates)
        commit(batch)
        after_commit(batch, user)

        Success(report)
      end

      private

      def validate_rows(rows)
        contract = Trading::Contracts::ImportTradeRowContract.new
        results = rows.each_with_index.map { |row, index| [ index + 1, contract.call(row) ] }
        invalid = results.reject { |_, result| result.success? }

        return Failure([ :invalid_rows, invalid.map { |number, result| { row: number, errors: result.errors.to_h } } ]) if invalid.any?

        Success(results.map { |_, result| result.to_h }.sort_by { |row| row[:executed_at] })
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
        pairs = parsed.map { |row| [ currency_of(row), executed_on(row) ] }.uniq
        rates = {}
        missing = []

        pairs.each do |currency, date|
          rate = Trading::Domain::ExecutionRate.capture(currency: currency, at_date: date)
          rate ? rates[[ currency, date ]] = rate : missing << "#{currency}->#{Trading::Domain::ExecutionRate::REFERENCE} on #{date}"
        end

        missing.any? ? Failure([ :missing_fx_history, missing.sort ]) : Success(rates)
      end

      def partition_already_imported(portfolio, parsed)
        ids = parsed.filter_map { |row| row[:external_id].presence }
        taken = ids.any? ? portfolio.trades.where(external_id: ids).pluck(:external_id).to_set : Set.new

        parsed.partition { |row| row[:external_id].blank? || !taken.include?(row[:external_id]) }
      end

      # A batch whose every row was already imported is the normal outcome of
      # confirming twice, not an error — there is simply nothing to open a
      # transaction for.
      def commit(batch)
        return if batch.rows.empty?

        ActiveRecord::Base.transaction do
          batch.rows.group_by { |row| row[:asset_symbol].upcase }.each do |symbol, asset_rows|
            replay_asset(batch, batch.assets.fetch(symbol), asset_rows)
          end

          backdate_inception(batch)
        end
      end

      def replay_asset(batch, asset, rows)
        position = open_position_for(batch, asset, rows)
        rows.each { |row| create_trade(batch, asset, position, row) }

        apply_share_movement(position, rows)
        position.recalculate_avg_cost!
      end

      # opened_at comes from the earliest trade, never from import day.
      def open_position_for(batch, asset, rows)
        positions = batch.portfolio.positions
        position = positions.find_by(asset: asset, status: :open) ||
                   positions.new(asset: asset, shares: 0, avg_cost: rows.first[:price_per_share], status: :open)

        earliest = Time.zone.parse(rows.first[:executed_at])
        position.opened_at = [ position.opened_at, earliest ].compact.min
        position.save!
        position
      end

      def create_trade(batch, asset, position, row)
        currency = currency_of(row)

        batch.portfolio.trades.create!(
          asset: asset,
          position: position,
          side: row[:side],
          shares: row[:shares],
          price_per_share: row[:price_per_share],
          fee: row[:fee] || 0,
          currency: currency,
          fx_rate_at_execution: batch.rates.fetch([ currency, executed_on(row) ]),
          external_id: row[:external_id].presence,
          executed_at: Time.zone.parse(row[:executed_at])
        )
      end

      def apply_share_movement(position, rows)
        delta = rows.sum { |row| row[:side] == "buy" ? row[:shares] : -row[:shares] }
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
      def backdate_inception(batch)
        earliest = earliest_date(batch.rows)
        inception = batch.portfolio.inception_date
        return if inception && inception <= earliest

        batch.portfolio.update!(inception_date: earliest)
      end

      # Outside the transaction on purpose: a rolled-back import must not leave
      # published events or rewritten snapshots behind.
      def after_commit(batch, user)
        return if batch.rows.empty?

        earliest = earliest_date(batch.rows)
        Trading::UseCases::RebuildSnapshots.call(portfolio: batch.portfolio, from: earliest)

        publish(Events::TradesImported.new(
          portfolio_id: batch.portfolio.id,
          user_id: user.id,
          trade_count: batch.rows.size,
          earliest_executed_on: earliest.to_s
        ))
      end

      def build_report(fresh, skipped, dry_run)
        dates = fresh.map { |row| executed_on(row) }

        {
          dry_run: dry_run,
          imported: fresh.size,
          skipped: skipped.map { |row| { asset_symbol: row[:asset_symbol], external_id: row[:external_id] } },
          invested: fresh.sum { |row| row[:shares] * row[:price_per_share] },
          symbols: fresh.map { |row| row[:asset_symbol].upcase }.uniq.sort,
          earliest_on: dates.min,
          latest_on: dates.max
        }
      end

      def earliest_date(rows) = rows.map { |row| executed_on(row) }.min

      def currency_of(row) = row[:currency].presence || "USD"

      def executed_on(row) = Time.zone.parse(row[:executed_at]).to_date
    end
  end
end
