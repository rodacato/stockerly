module Trading
  module Domain
    # The portfolio's time-weighted return against leaving the money in CETES,
    # rolled into a new auction each time the term matures. Nil when the
    # period has no CETES rate to start from: no comparison beats an invented one.
    class CetesComparison
      TERM = "28"

      def self.between(mine, from, to)
        theirs = MarketData::Queries::CetesReinvestedReturn.call(term: TERM, from: from, to: to)
        return nil if theirs.nil?

        # The card prints both returns at one decimal, so the gap is judged on those.
        { points: (mine.round(1) - theirs.round(1)).round(1), mine: mine, benchmark: theirs, term: TERM }
      end
    end
  end
end
