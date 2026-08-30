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

        range.count { |date| write(portfolio, date, currency, valuation.market_value_on(date)) }
      end

      private

      # Never before the portfolio existed, never past today.
      def bounded_range(portfolio, from, to)
        first = [ from, portfolio.inception_date ].compact.max
        last  = [ to, Date.current ].min
        return nil if first > last

        first..last
      end

      # Idempotent by (portfolio_id, date), which carries a unique index —
      # a rebuild that raced the nightly job would otherwise collide.
      def write(portfolio, date, currency, market_value)
        snapshot = portfolio.snapshots.find_or_initialize_by(date: date)
        snapshot.update!(currency: currency, total_value: market_value)
        true
      end
    end
  end
end
