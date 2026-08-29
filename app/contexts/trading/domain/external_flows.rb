module Trading
  module Domain
    # Capital entering or leaving the portfolio, valued in one currency.
    # With no cash model (D26) every buy is an inflow and every sell an
    # outflow, so the trades are the only record of them.
    class ExternalFlows
      def initialize(portfolio, currency:)
        @portfolio = portfolio
        @currency  = currency
      end

      # Flows a snapshot could not have seen. Keyed on when the trade was
      # recorded, because that is what decides whether the snapshot includes
      # it — the date typed on the form does not.
      def since(time)
        total_of(@portfolio.trades.kept.where(created_at: time..))
      end

      # Flows per day across a range, for a history that has been rebuilt to
      # agree with the trades. Here the executed date is the right key: the
      # snapshot for a day was computed from exactly these trades.
      #
      # Returns a Hash defaulting to 0, built from one query — a year of daily
      # sub-periods would otherwise ask 365 times.
      def by_date(range)
        trades = @portfolio.trades.kept.where(executed_at: range.first.beginning_of_day..range.last.end_of_day)

        trades.group_by { |trade| trade.executed_at.to_date }
              .each_with_object(Hash.new(0)) { |(date, group), acc| acc[date] = total_of(group) }
      end

      private

      def total_of(trades)
        trades.sum do |trade|
          amount = trade.shares * trade.price_per_share * rate_for(trade)
          trade.side == "sell" ? -amount : amount
        end
      end

      # Fees are excluded: they never entered market value, so subtracting
      # them would invent a loss.
      # A trade with no captured rate predates the column; the portfolio's own
      # dated conversion is the only thing left to value it with.
      def rate_for(trade)
        return Trading::Domain::ExecutionRate.multiplier(trade: trade, target: @currency) if trade.fx_rate_at_execution
        return 1 if trade.currency == @currency

        @portfolio.convert(1, from: trade.currency, to: @currency, at_date: trade.executed_at.to_date)
      end
    end
  end
end
