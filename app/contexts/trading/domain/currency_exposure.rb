module Trading
  module Domain
    # How much of the patrimonio is quoted in dollars, and what a move of the
    # dollar would do to it in pesos. A what-if over today's figures, never a forecast.
    class CurrencyExposure
      MOVE_PERCENT = 5

      Result = Data.define(:usd_value, :total) do
        def usd_share = (usd_value / total * 100).round
        def effect_of(percent) = usd_value * percent / 100
      end

      # `by_currency` is value per asset currency, all in MXN.
      def self.call(by_currency:)
        total = by_currency.values.sum
        return nil unless total.positive?

        Result.new(usd_value: by_currency.fetch("USD", 0), total: total)
      end
    end
  end
end
