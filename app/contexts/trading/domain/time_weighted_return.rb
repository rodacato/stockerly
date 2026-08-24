module Trading
  module Domain
    # Time-weighted return: what the portfolio earned, with the effect of
    # putting money in or taking it out removed.
    #
    # D12 is the reason this exists. PeriodReturnsCalculator diffs today's
    # total against an older snapshot, so a deposit makes the "return" rise
    # while nothing performed better. Comparing that against CETES would state
    # a falsehood on the one screen whose entire job is "did this beat doing
    # nothing".
    #
    # Each day is its own sub-period, chained by multiplication, so a day that
    # doubles the portfolio and a day that halves it cancel out — which is what
    # "time-weighted" means and what a plain start-to-end diff cannot express.
    class TimeWeightedReturn
      Period = Data.define(:date, :value, :flow)

      def initialize(portfolio, currency: nil)
        @portfolio = portfolio
        @currency  = currency || portfolio.user.preferred_currency
        @flows     = ExternalFlows.new(portfolio, currency: @currency)
      end

      # Percent for the whole range, not annualized: the screen compares
      # periods of the same length against each other.
      def between(from:, to: Date.current)
        periods = periods_in(from, to)
        return 0.0 if periods.size < 2

        growth = periods.each_cons(2).reduce(1.0) do |acc, (previous, current)|
          acc * (1 + sub_period_return(previous, current))
        end

        ((growth - 1) * 100).to_f
      end

      private

      # The flow is already inside `current.value` — the snapshot was taken at
      # the end of the day, after the trade. Removing it leaves what the market
      # did, measured against the capital that was actually at risk.
      #
      # A sub-period that starts from nothing has no capital at risk and no
      # return to speak of: the first deposit is not a gain.
      def sub_period_return(previous, current)
        base = previous.value
        return 0.0 unless base.positive?

        (current.value - current.flow - base) / base
      end

      def periods_in(from, to)
        snapshots = @portfolio.snapshots.where(date: from..to).order(:date).to_a
        return [] if snapshots.empty?

        flows = @flows.by_date(snapshots.first.date..snapshots.last.date)

        snapshots.map do |snapshot|
          date = snapshot.date
          Period.new(date: date, value: value_of(snapshot), flow: flows[date])
        end
      end

      # ADR-009: a past snapshot is worth what it was worth on its own date,
      # not what today's rate would make of it.
      def value_of(snapshot)
        @portfolio.convert(snapshot.total_value, from: snapshot.currency, to: @currency, at_date: snapshot.date)
      end
    end
  end
end
