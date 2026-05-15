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

      def buying_power
        portfolio.convert(portfolio.buying_power, from: portfolio.buying_power_currency, to: currency)
      end

      def unrealized_gain
        gain = portfolio.total_unrealized_gain(currency: currency)
        base = total_invested
        percent = base.positive? ? (gain / base * 100) : 0.0
        GainLoss.new(absolute: gain.to_f, percent: percent.to_f)
      end

      def day_gain
        yesterday = portfolio.yesterday_snapshot
        return GainLoss.new(absolute: 0.0, percent: 0.0) unless yesterday

        yesterday_total = total_value_of(yesterday)
        diff = total_value - yesterday_total
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
          buying_power: buying_power,
          unrealized_gain: unrealized_gain,
          day_gain: day_gain,
          total_invested: total_invested,
          currency: currency
        }
      end

      private

      def total_value_of(snapshot)
        portfolio.convert(snapshot.total_value, from: snapshot.currency, to: currency)
      end
    end
  end
end
