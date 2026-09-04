module MarketData
  module Gateways
    # Fetches the Crypto Fear & Greed Index from Alternative.me.
    # Free, no auth required.
    # Docs: https://alternative.me/crypto/fear-and-greed-index/
    class CryptoFearGreedGateway
    include PerformsRequests
    include Dry::Monads[:result]

    BASE_URL = "https://api.alternative.me"

    PROVIDER = "Alternative.me"
    TIMEOUT  = 5

    def fetch_index
      result = get_json("/fng/", { limit: 1 })
      return result if result.failure?

      parse(result.value!)
    end

    private

    def connection
      build_connection(url: BASE_URL, timeout: TIMEOUT, retry_options: { max: 2, interval: 0.5 })
    end

    def parse(body)
      data = body["data"]&.first
      return Failure([ :parse_error, "No data in Alternative.me response" ]) unless data

      Success({
        value: data["value"].to_i,
        classification: data["value_classification"],
        fetched_at: Time.at(data["timestamp"].to_i),
        component_data: {}
      })
    rescue StandardError => e
      Failure([ :parse_error, "Failed to parse Alternative.me response: #{e.message}" ])
    end
    end
  end
end
