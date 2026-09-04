module MarketData
  module Gateways
    # Driven adapter: exchangerate-api.com for foreign exchange rates.
    # Separate output port — does NOT inherit from MarketDataGateway
    # because the contract is fundamentally different (FX pairs, not asset prices).
    class FxRatesGateway
    include PerformsRequests
    include ResolvesApiKey
    include Dry::Monads[:result]

    BASE_URL = "https://v6.exchangerate-api.com"
    PROVIDER = "ExchangeRate"
    TIMEOUT  = 5

    def initialize(api_key: nil)
      @api_key = api_key || resolve_api_key
    end

    # Refresh FX rates for given base → target currencies.
    # Upserts FxRate records and returns Success(:rates_refreshed).
    def refresh_rates(base: "USD", targets: %w[EUR MXN GBP JPY])
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      result = get_json("/v6/#{@api_key}/latest/#{base}")
      return result if result.failure?

      parse_and_upsert(base, targets, result.value!)
    end

    private

    def connection
      build_connection(url: BASE_URL, timeout: TIMEOUT,
                       retry_options: { max: 2, interval: 1, backoff_factor: 2, retry_statuses: [ 500, 502, 503 ] })
    end

    def parse_and_upsert(base, targets, body)
      rates = body.dig("conversion_rates")
      return Failure([ :gateway_error, "No conversion_rates in response" ]) unless rates

      now = Time.current
      targets.each do |target|
        rate = rates[target]
        next unless rate

        FxRate.upsert(
          { base_currency: base, quote_currency: target, rate: rate.to_d, fetched_at: now,
            created_at: now, updated_at: now },
          unique_by: %i[base_currency quote_currency]
        )
      end

      Success(:rates_refreshed)
    end
    end
  end
end
