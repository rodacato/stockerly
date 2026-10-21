module Trading
  module Domain
    # The portfolio's time-weighted return against the IPC over the same
    # dates. The IPC is quoted in pesos, so no exchange rate stands between the
    # two. Nil when either end of the period has no close: no comparison beats
    # an invented one.
    class IndexComparison
      SYMBOL = "IPC"

      def self.between(mine, from, to)
        theirs = MarketData::Queries::IndexReturn.call(symbol: SYMBOL, from: from, to: to)
        return nil if theirs.nil?

        { points: (mine.round(1) - theirs.round(1)).round(1), mine: mine, benchmark: theirs, symbol: SYMBOL }
      end
    end
  end
end
