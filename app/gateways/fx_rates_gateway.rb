# Driven adapter: exchangerate-api.com for foreign exchange rates.
# Separate output port — does NOT inherit from MarketDataGateway
# because the contract is fundamentally different (FX pairs, not asset prices).
class FxRatesGateway
  include Dry::Monads[:result]

  BASE_URL = "https://v6.exchangerate-api.com"
  TIMEOUT  = 5

  def initialize(api_key: nil)
    @api_key = api_key || resolve_api_key
  end

  # Refresh FX rates for given base → target currencies.
  # Upserts FxRate records and returns Success(:rates_refreshed).
  def refresh_rates(base: "USD", targets: %w[EUR MXN GBP JPY])
    response = connection.get("/v6/#{@api_key}/latest/#{base}")

    return Failure([ :rate_limited, "ExchangeRate API rate limit exceeded" ]) if response.status == 429
    return Failure([ :gateway_error, "ExchangeRate API returned #{response.status}" ]) unless response.success?

    parse_and_upsert(base, targets, response.body)
  rescue Faraday::Error => e
    Failure([ :gateway_error, e.message ])
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :retry, max: 2, interval: 1, backoff_factor: 2,
                        retry_statuses: [ 500, 502, 503 ]
      f.response :json
      f.options.timeout = TIMEOUT
      f.options.open_timeout = TIMEOUT
    end
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

  def resolve_api_key
    Integration.find_by(provider_name: "ExchangeRate")&.api_key_encrypted ||
      ENV.fetch("EXCHANGERATE_API_KEY", "")
  end
end
