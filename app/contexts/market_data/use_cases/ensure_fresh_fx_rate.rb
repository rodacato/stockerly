module MarketData
  module UseCases
    # Read-through cache for FX rates (ADR-002 supplier-side wrapper).
    # Trading callers ask for `base → target`; this use case reads the local
    # FxRate cache, refreshes from the external gateway on miss, retries the
    # read, and falls back to the inverse direction before giving up. Returns
    # the rate (BigDecimal) or nil. The internal write to the FxRate AR model
    # is a cache update within MarketData's own ownership — NOT a cross-context
    # write from Trading.
    class EnsureFreshFxRate
      def self.call(base:, target:)
        base = base.to_s.upcase
        target = target.to_s.upcase

        # 1. Direct cache lookup.
        rate = FxRate.convert(1, from: base, to: target)
        return rate if rate

        # 2. Cache miss → refresh from gateway, retry direct lookup.
        refresh_from_gateway(base: base, target: target)
        rate = FxRate.convert(1, from: base, to: target)
        return rate if rate

        # 3. Still missing → inverse direction (refresh may have populated
        #    target → base even when base → target failed).
        inverse = FxRate.convert(1, from: target, to: base)
        return BigDecimal(1) / inverse if inverse && inverse.positive?

        nil
      end

      def self.refresh_from_gateway(base:, target:)
        Gateways::FxRatesGateway.new.refresh_rates(base: base, targets: [ target ])
      rescue StandardError
        nil
      end
      private_class_method :refresh_from_gateway
    end
  end
end
