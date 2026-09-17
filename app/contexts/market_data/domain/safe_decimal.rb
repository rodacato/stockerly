module MarketData
  module Domain
    # Coerces provider payload values to BigDecimal, mapping missing-value
    # sentinels to nil. Included rather than inherited: the two call sites
    # (a gateway and the calculator) share no base class.
    module SafeDecimal
      # "None" is Alpha Vantage's sentinel, still inside statements it stored;
      # "-" has been carried by stored payloads since 2026-02.
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
