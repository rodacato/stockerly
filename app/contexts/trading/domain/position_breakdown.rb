module Trading
  module Domain
    # Splits a position's unrealised gain into what the asset did and what the
    # peso did. For a MXN investor holding USD assets these are different
    # stories — the asset can rise while the currency eats the gain, and the
    # product exists partly to tell them apart (JTBD #1, ADR-009).
    #
    # The two parts sum to the total by construction:
    #   asset part = shares × (price − avg_cost) × today's rate
    #   fx part    = shares × avg_cost × today's rate − cost basis at historical rates
    class PositionBreakdown
      Part = Data.define(:amount, :percent)

      def initialize(position, currency:)
        @position = position
        @currency = currency
        @portfolio = position.portfolio
      end

      def total = Part.new(amount: market_value - cost_basis, percent: percent_of(market_value - cost_basis))

      def from_asset
        native = @position.shares * (price - @position.avg_cost)
        amount = convert(native)
        Part.new(amount: amount, percent: percent_of(amount))
      end

      # What the exchange rate did to the money already committed: the cost
      # revalued at today's rate, minus what it actually cost in pesos.
      def from_fx
        return Part.new(amount: 0, percent: 0) if same_currency?

        amount = convert(@position.shares * @position.avg_cost) - cost_basis
        Part.new(amount: amount, percent: percent_of(amount))
      end

      def same_currency? = @position.asset.currency == @currency

      def cost_basis = @cost_basis ||= @position.cost_basis_in(@currency)

      def market_value = @market_value ||= convert(@position.shares * price)

      private

      def price = @position.asset.current_price || 0

      def convert(native) = @portfolio.convert(native, from: @position.asset.currency, to: @currency)

      def percent_of(amount)
        base = cost_basis
        return 0 unless base.positive?

        (amount / base * 100).to_f
      end
    end
  end
end
