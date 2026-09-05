module Trading
  module Domain
    # Capital entering or leaving the portfolio, valued in one currency.
    # With no cash model (D26) every buy is an inflow and every sell an
    # outflow, so the trades are the only record of them.
    class ExternalFlows
      # `asset` narrows every flow to one position's trades. The arithmetic is
      # identical — a buy is still an inflow — so the scope is a filter rather
      # than a second calculation.
      def initialize(portfolio, currency:, asset: nil)
        @portfolio = portfolio
        @currency  = currency
        @asset     = asset
      end

      # Net capital put into this scope between two dates, inclusive of both.
      # A window's return is what is left after removing it: money you added
      # is not money the position earned (D12, at position scope).
      def between(from, to)
        total_of(trades.where(executed_at: from.beginning_of_day..to.end_of_day))
      end

      # Flows a snapshot could not have seen. Keyed on when the trade was
      # recorded, because that is what decides whether the snapshot includes
      # it — the date typed on the form does not.
      def since(time)
        total_of(trades.where(created_at: time..))
      end

      # Flows per day across a range, for a history that has been rebuilt to
      # agree with the trades. Here the executed date is the right key: the
      # snapshot for a day was computed from exactly these trades.
      #
      # Returns a Hash defaulting to 0, built from one query — a year of daily
      # sub-periods would otherwise ask 365 times.
      def by_date(range)
        rows = trades.where(executed_at: range.first.beginning_of_day..range.last.end_of_day)

        rows.group_by { |trade| trade.executed_at.to_date }
              .each_with_object(Hash.new(0)) { |(date, group), acc| acc[date] = total_of(group) }
      end

      private

      def trades
        scope = @portfolio.trades.kept
        @asset ? scope.where(asset_id: @asset.id) : scope
      end

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
