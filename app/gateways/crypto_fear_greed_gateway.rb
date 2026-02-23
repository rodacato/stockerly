# Fetches the Crypto Fear & Greed Index from Alternative.me.
# Free, no auth required. Rate limit: ~50 req/day.
# Docs: https://alternative.me/crypto/fear-and-greed-index/
class CryptoFearGreedGateway
  include Dry::Monads[:result]

  BASE_URL = "https://api.alternative.me"
  TIMEOUT  = 5

  def fetch_index
    response = connection.get("/fng/", limit: 1)

    return Failure([:rate_limited, "Alternative.me rate limit exceeded"]) if response.status == 429
    return Failure([:gateway_error, "Alternative.me returned #{response.status}"]) unless response.success?

    parse(response.body)
  rescue Faraday::Error => e
    Failure([:gateway_error, e.message])
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.options.timeout = TIMEOUT
      f.options.open_timeout = TIMEOUT
      f.request :retry, max: 2, interval: 0.5
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def parse(body)
    data = body["data"]&.first
    return Failure([:parse_error, "No data in Alternative.me response"]) unless data

    Success({
      value: data["value"].to_i,
      classification: data["value_classification"],
      fetched_at: Time.at(data["timestamp"].to_i),
      component_data: {}
    })
  rescue StandardError => e
    Failure([:parse_error, "Failed to parse Alternative.me response: #{e.message}"])
  end
end
