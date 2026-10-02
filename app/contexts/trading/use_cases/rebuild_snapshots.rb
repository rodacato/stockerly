module Trading
  module UseCases
    # Recomputes portfolio_snapshots for a date range from the trades. Nothing
    # else ever rewrites a past snapshot: TakeSnapshotsJob only writes today,
    # so a trade recorded late left every day before it describing a portfolio
    # that did not include it.
    class RebuildSnapshots < SimpleUseCase
      def call(portfolio:, from:, to: Date.current)
        currency = portfolio.user.preferred_currency
        range = bounded_range(portfolio, from, to)
        return 0 if range.nil?

        valuation = Domain::HistoricalValuation.new(portfolio, currency: currency)

        write(portfolio, currency, range.map { |date| [ date, valuation.market_value_on(date) ] })
      end

      private

      # Never before the portfolio existed, never past today.
      def bounded_range(portfolio, from, to)
        first = [ from, portfolio.inception_date ].compact.max
        last  = [ to, Date.current ].min
        return nil if first > last

        first..last
      end

      # One statement for the whole range: a year of history was ~900 queries
      # (a find and an insert per day), which put the import's redirect past
      # the browser spec's wait. Idempotent by (portfolio_id, date), which
      # carries a unique index — a rebuild that raced the nightly job would
      # otherwise collide.
      def write(portfolio, currency, values)
        now = Time.current
        rows = values.map do |date, market_value|
          { portfolio_id: portfolio.id, date: date, currency: currency, total_value: market_value,
            created_at: now, updated_at: now }
        end
        PortfolioSnapshot.upsert_all(rows, unique_by: %i[portfolio_id date], update_only: %i[currency total_value]) # rubocop:disable Rails/SkipsModelValidations -- rows are built from typed values above
        rows.size
      end
    end
  end
end
