module Trading
  module Domain
    # What a closed position actually made, in the user's currency.
    #
    # `TradesHelper#trades_summary_by_currency` also computes a realized number
    # and its own comment admits it drifts: it values a sale against the
    # position's *current* avg cost, which is not the cost at the moment of the
    # sale. That approximation exists because an open position's history is
    # still moving. **A closed position has no such problem** — every trade it
    # will ever have already exists, so the gain is the difference between what
    # the sales brought in and what the purchases cost, and nothing has to be
    # estimated.
    #
    # Each leg converts at its own `fx_rate_at_execution`, which is the whole
    # point of capturing it: a peso gain earned at 17.20 does not become a
    # different number because today's rate is 18.40.
    class RealizedGain
      def initialize(position, currency:)
        @position = position
        @currency = currency
      end

      def amount
        return 0.to_d if trades.empty?

        proceeds - cost
      end

      private

      attr_reader :position, :currency

      def trades
        @trades ||= position.trades.select { |t| t.discarded_at.nil? }
      end

      def proceeds
        total_for("sell") { |trade| gross(trade) - fee(trade) }
      end

      def cost
        total_for("buy") { |trade| gross(trade) + fee(trade) }
      end

      def total_for(side)
        trades.select { |t| t.side == side }.sum { |trade| yield(trade) }
      end

      def gross(trade)
        trade.shares * trade.price_per_share * rate(trade)
      end

      def fee(trade)
        (trade.fee || 0) * rate(trade)
      end

      # Fail loud rather than silently valuing a leg at 1:1 — a wrong gain on a
      # money screen is worse than a page that says it cannot compute one.
      def rate(trade)
        return 1.to_d if currency == trade.currency

        trade.fx_rate_at_execution ||
          raise(MissingFxRate,
                "Trade##{trade.id}: no fx_rate_at_execution; cannot state the realized gain in #{currency}")
      end
    end
  end
end
