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
    # Cross-context call to MarketData::Gateways::FxRatesGateway is a known leak
    # tracked for Sprint 5 (architectural).
    class FxRateResolver
      extend Dry::Monads[:result]

      def self.call(trade_currency:, preferred_currency:, override: nil)
        trade_currency = trade_currency.to_s.upcase
        preferred_currency = preferred_currency.to_s.upcase

        return Success(BigDecimal(1)) if trade_currency == preferred_currency
        return Success(override) if override

        rate = FxRate.convert(1, from: trade_currency, to: preferred_currency)
        return Success(rate) if rate

        refresh_fx_rates(base: trade_currency, target: preferred_currency)
        rate = FxRate.convert(1, from: trade_currency, to: preferred_currency)
        return Success(rate) if rate

        inverse = FxRate.convert(1, from: preferred_currency, to: trade_currency)
        return Success(BigDecimal(1) / inverse) if inverse && inverse > 0

        Failure([ :fx_rate_unavailable, "Could not determine FX rate: #{trade_currency} -> #{preferred_currency}" ])
      end

      def self.refresh_fx_rates(base:, target:)
        MarketData::Gateways::FxRatesGateway.new.refresh_rates(base: base, targets: [ target ])
      rescue StandardError
        nil
      end
      private_class_method :refresh_fx_rates
    end
  end
end
