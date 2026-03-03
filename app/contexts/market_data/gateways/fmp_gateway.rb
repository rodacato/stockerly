module MarketData
  module Gateways
    # Driven adapter: Financial Modeling Prep API for dividend and split data.
    # Free tier: 250 calls/day. Docs: https://financialmodelingprep.com/developer/docs
    class FmpGateway < MarketDataGateway
    include Dry::Monads[:result]

    BASE_URL = "https://financialmodelingprep.com"
    PROVIDER = "FMP"
    TIMEOUT  = 10

    def initialize(api_key: nil)
      @api_key = api_key || resolve_api_key
    end

    # Fetch historical dividends for a stock symbol.
    # Returns Success([{ ex_date:, pay_date:, amount_per_share:, currency: }, ...])
    def fetch_dividends(symbol)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("/api/v3/historical-price-full/stock_dividend/#{symbol}") do |req|
        req.params["apikey"] = @api_key
      end

      return Failure([ :rate_limited, "FMP rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "FMP returned #{response.status}" ]) unless response.success?

      parse_dividends(response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Fetch historical stock splits for a symbol.
    # Returns Success([{ date:, numerator:, denominator: }, ...])
    def fetch_splits(symbol)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("/api/v3/historical-price-full/stock_split/#{symbol}") do |req|
        req.params["apikey"] = @api_key
      end

      return Failure([ :rate_limited, "FMP rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "FMP returned #{response.status}" ]) unless response.success?

      parse_splits(response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    private

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                          retry_statuses: [ 500, 502, 503 ]
        f.response :json
        f.options.timeout = TIMEOUT
        f.options.open_timeout = TIMEOUT
      end
    end

    def parse_dividends(body)
      historical = body["historical"]
      return Success([]) unless historical.is_a?(Array)

      dividends = historical.filter_map do |entry|
        next unless entry["date"].present? && entry["dividend"].present?

        {
          ex_date: Date.parse(entry["date"]),
          pay_date: entry["paymentDate"].present? ? Date.parse(entry["paymentDate"]) : nil,
          amount_per_share: entry["dividend"].to_d,
          currency: "USD"
        }
      rescue Date::Error
        next
      end

      Success(dividends)
    end

    def parse_splits(body)
      historical = body["historical"]
      return Success([]) unless historical.is_a?(Array)

      splits = historical.filter_map do |entry|
        next unless entry["date"].present? && entry["numerator"].present? && entry["denominator"].present?

        {
          date: Date.parse(entry["date"]),
          numerator: entry["numerator"].to_i,
          denominator: entry["denominator"].to_i
        }
      rescue Date::Error
        next
      end

      Success(splits)
    end

    def resolve_api_key
      Integration.find_by(provider_name: PROVIDER)&.api_key_encrypted ||
        ENV.fetch("FMP_API_KEY", "")
    rescue ActiveRecord::Encryption::Errors::Decryption
      ENV.fetch("FMP_API_KEY", "")
    end
    end
  end
end
