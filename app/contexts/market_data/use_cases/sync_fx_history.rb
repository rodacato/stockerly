module MarketData
  module UseCases
    # Fills FxRateHistory from Banxico's FIX (ADR-009 + #177). Banxico is the
    # source because it is the rate a Mexican broker settles against — the
    # generic provider behind `fx_rates` drifts 0.5-1% from it daily, which is
    # the difference between a figure Adrian can check and one he cannot.
    class SyncFxHistory < ApplicationUseCase
      DEFAULT_LOOKBACK = 7

      def call(from: nil, to: Date.current, gateway: nil)
        from ||= to - DEFAULT_LOOKBACK
        gateway ||= MarketData::Gateways::BanxicoGateway.new

        fixes = yield banxico_breaker.call { gateway.fetch_fx_fixes(from: from, to: to) }
        stored = persist(fixes)

        Success(stored: stored, from: from, to: to)
      rescue MarketData::Gateways::ApiKeyNotConfiguredError => e
        Failure([ :not_configured, e.message ])
      end

      private

      # Banxico blocks an abusing token for a full calendar day, and that token
      # serves FX and CETES alike, so the direct call runs under its breaker too.
      def banxico_breaker
        GatewayChain.breaker_for("banxico")
      end

      def persist(fixes)
        pair = MarketData::Gateways::BanxicoGateway::FIX_PAIR

        FxRateHistory.record_all(
          fixes.map do |fix|
            {
              base_currency: pair[:base],
              quote_currency: pair[:quote],
              rate_date: fix[:date],
              rate: fix[:rate],
              source: MarketData::Gateways::BanxicoGateway::FIX_SOURCE_ID
            }
          end
        )
      end
    end
  end
end
