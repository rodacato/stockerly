module MarketData
  module Domain
    # Coerces provider payload values to BigDecimal, mapping missing-value
    # sentinels to nil. Included rather than inherited: the three call sites
    # (two gateways, one calculator) share no base class.
    module SafeDecimal
      # "None" is Alpha Vantage's documented sentinel; "-" is undocumented by
      # either provider and kept because payloads have carried it since 2026-02.
      MISSING_VALUE_SENTINELS = [ "None", "-" ].freeze

      private

      def safe_decimal(value)
        return nil if value.blank? || MISSING_VALUE_SENTINELS.include?(value)
        BigDecimal(value.to_s)
      rescue ArgumentError
        nil
      end
    end
  end
end
