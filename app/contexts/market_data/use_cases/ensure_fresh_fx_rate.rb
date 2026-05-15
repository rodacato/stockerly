module MarketData
  module UseCases
    # Read-through cache for FX rates (ADR-002 supplier-side wrapper).
    # Trading callers ask for `base → target`; this use case reads the local
    # FxRate cache, refreshes from the external gateway on miss, retries the
    # read, and falls back to the inverse direction before giving up. The
    # internal write to the FxRate AR model is a cache update within
    # MarketData's own ownership — NOT a cross-context write from Trading.
    #
    # Inherits from ApplicationUseCase to match the project convention
    # (CLAUDE.md "ApplicationUseCase Base Class"). Returns Success(rate) or
    # Failure([:fx_rate_unavailable, msg]); the latter is intentionally the
    # same tag and message format that FxRateResolver previously emitted, so
    # downstream ExecuteTrade can pattern-match without changes.
    class EnsureFreshFxRate < ApplicationUseCase
      def call(base:, target:)
        base = base.to_s.upcase
        target = target.to_s.upcase

        rate = FxRate.convert(1, from: base, to: target)
        return Success(rate) if rate

        refresh_from_gateway(base: base, target: target)
        rate = FxRate.convert(1, from: base, to: target)
        return Success(rate) if rate

        inverse = FxRate.convert(1, from: target, to: base)
        return Success(BigDecimal(1) / inverse) if inverse && inverse.positive?

        Failure([ :fx_rate_unavailable, "Could not determine FX rate: #{base} -> #{target}" ])
      end

      private

      def refresh_from_gateway(base:, target:)
        Gateways::FxRatesGateway.new.refresh_rates(base: base, targets: [ target ])
      rescue StandardError => e
        Rails.logger.error("[MarketData] FX refresh failed for #{base}->#{target}: #{e.message}")
        nil
      end
    end
  end
end
