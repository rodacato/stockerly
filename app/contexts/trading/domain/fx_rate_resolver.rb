module Trading
  module Domain
    # Resolves the FX rate expressing 1 unit of `trade_currency` in `preferred_currency`.
    # Single source of truth shared by Trading::UseCases::ExecuteTrade (#42) and the
    # fx_rate_backfill rake task (#44).
    #
    # Resolution order:
    #   1. Same currency → 1.0 (no gateway call)
    #   2. Explicit override (manual entry / future use cases)
    #   3. Latest FxRate row in DB (forward direction)
    #   4. Best-effort gateway refresh, retry forward
    #   5. Inverse FxRate row (1 / reverse rate)
    #   6. Failure(:fx_rate_unavailable)
    #
    # Important: this captures the FX rate *at resolution time*, not at trade
    # execution time. The schema does not store historical FX (decision documented
    # for #42, deferred to a future issue when beta usage demands it). For backdated
    # trades requiring precision, callers may supply `override`.
    #
    # The cache + refresh + inverse-fallback logic lives in
    # MarketData::UseCases::EnsureFreshFxRate (ADR-002 supplier-side wrapper).
    # This class adds Trading-specific concerns: same-currency shortcut, explicit
    # override, and the Success/Failure monad surface that ExecuteTrade consumes
    # via `yield`.
    class FxRateResolver
      extend Dry::Monads[:result]

      def self.call(trade_currency:, preferred_currency:, override: nil)
        trade_currency = trade_currency.to_s.upcase
        preferred_currency = preferred_currency.to_s.upcase

        return Success(BigDecimal(1)) if trade_currency == preferred_currency
        return Success(override) if override

        # EnsureFreshFxRate already emits the canonical
        # Failure([:fx_rate_unavailable, "Could not determine FX rate: X -> Y"])
        # — pass through unchanged.
        MarketData::UseCases::EnsureFreshFxRate.call(base: trade_currency, target: preferred_currency)
      end
    end
  end
end
