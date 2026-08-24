module Trading
  module Domain
    class PortfolioSummary
      attr_reader :portfolio, :currency

      def initialize(portfolio, currency: nil)
        @portfolio = portfolio
        @currency  = currency || portfolio.user.preferred_currency
      end

      def total_value
        portfolio.total_value(currency: currency)
      end

      def unrealized_gain
        gain = portfolio.total_unrealized_gain(currency: currency)
        base = total_invested
        percent = base.positive? ? (gain / base * 100) : 0.0
        GainLoss.new(absolute: gain.to_f, percent: percent.to_f)
      end

      # Capital put in or taken out is not a gain. A trade recorded after
      # yesterday's snapshot is in today's total and absent from that snapshot,
      # so without subtracting it a purchase reads as market movement — a
      # backdated buy of 1,000 against a 5,000 portfolio reported "+20.0% hoy"
      # while no price had moved.
      def day_gain
        yesterday = portfolio.yesterday_snapshot
        return GainLoss.new(absolute: 0.0, percent: 0.0) unless yesterday

        yesterday_total = total_value_of(yesterday)
        diff = total_value - yesterday_total - external_flows_since(yesterday)
        percent = yesterday_total.positive? ? (diff / yesterday_total * 100) : 0.0
        GainLoss.new(absolute: diff.to_f, percent: percent.to_f)
      end

      # Historical-FX cost basis: each open position contributes its
      # weighted-average buy-trade cost translated by the FX rate captured
      # at execution time (Trade#fx_rate_at_execution, added in S2 #42).
      # This is what makes Gain/Loss percent honest for a mixed MXN+USD
      # portfolio — the previous implementation summed raw asset-currency
      # avg_cost across positions.
      #
      # Eager-loads trades so Position#cost_basis_in iterates the loaded
      # collection in Ruby instead of issuing a per-position SQL query.
      def total_invested
        portfolio.open_positions.includes(:asset, :trades).sum do |p|
          p.cost_basis_in(currency)
        end
      end

      def to_h
        {
          total_value: total_value,
          unrealized_gain: unrealized_gain,
          day_gain: day_gain,
          total_invested: total_invested,
          currency: currency
        }
      end

      private

      # What the snapshot could not have seen: every trade recorded after it was
      # taken, whatever date the user typed on the form. Buys add capital, sells
      # remove it; fees are excluded because they never entered market value.
      def external_flows_since(snapshot)
        portfolio.trades.kept.where(created_at: snapshot.created_at..).sum do |trade|
          amount = trade.shares * trade.price_per_share * flow_rate(trade)
          trade.side == "sell" ? -amount : amount
        end
      end

      def flow_rate(trade)
        captured = trade.fx_rate_at_execution
        return captured if captured

        from = trade.currency
        return 1 if from == currency

        portfolio.convert(1, from: from, to: currency, at_date: trade.executed_at.to_date)
      end

      # ADR-009: value the snapshot at ITS date, not today's. Revaluing
      # yesterday at today's rate reports FX movement on the principal as no
      # movement at all — the gap #183 measured at 1,500 MXN on a 3,000 USD
      # position over a single day.
      def total_value_of(snapshot)
        portfolio.convert(snapshot.total_value, from: snapshot.currency, to: currency, at_date: snapshot.date)
      end
    end
  end
end
