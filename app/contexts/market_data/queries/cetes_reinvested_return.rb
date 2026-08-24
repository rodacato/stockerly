module MarketData
  module Queries
    # Public read API: what holding CETES over a period would have returned,
    # rolling into a new auction each time the term matures.
    #
    # ADR-002: Trading asks this rather than reaching into CetesRateHistory.
    # Returns nil when the period has no rate to start from — the screen says
    # it cannot compare rather than inventing a benchmark to lose against.
    class CetesReinvestedReturn
      def self.call(term: "28", from:, to: Date.current)
        days = term.to_i
        return nil if days <= 0 || from >= to

        growth = BigDecimal("1")
        cursor = from

        while cursor < to
          rate = CetesRateHistory.rate_on(term: term, date: cursor)
          return nil if rate.nil?

          rolls_on = [ cursor + days, to ].min
          growth *= 1 + Domain::YieldCalculator.period_return(annual_yield: rate, days: (rolls_on - cursor).to_i)
          cursor = rolls_on
        end

        ((growth - 1) * 100).to_f
      end
    end
  end
end
