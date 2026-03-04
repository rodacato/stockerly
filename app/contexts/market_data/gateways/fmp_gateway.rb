module MarketData
  module Gateways
    # Driven adapter: Financial Modeling Prep API for fundamentals, dividends, and splits.
    # Free tier: 250 calls/day. Docs: https://financialmodelingprep.com/developer/docs
    class FmpGateway < MarketDataGateway
    include Dry::Monads[:result]

    BASE_URL = "https://financialmodelingprep.com"
    PROVIDER = "FMP"
    TIMEOUT  = 10

    def initialize(api_key: nil)
      @api_key = api_key || resolve_api_key
    end

    # Fetch company overview (profile + key metrics).
    # Returns Success({ symbol:, name:, eps:, market_cap:, ... }) matching AlphaVantageGateway schema.
    def fetch_overview(symbol)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("/api/v3/profile/#{symbol}") do |req|
        req.params["apikey"] = @api_key
      end

      return Failure([ :rate_limited, "FMP rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "FMP returned #{response.status}" ]) unless response.success?

      parse_overview(response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
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

    def parse_overview(body)
      return Failure([ :not_found, "No profile data from FMP" ]) unless body.is_a?(Array) && body.first.present?

      profile = body.first
      price = safe_decimal(profile["price"])
      eps = safe_decimal(profile["eps"] || profile["lastDiv"])

      Success({
        symbol: profile["symbol"],
        name: profile["companyName"],
        description: profile["description"],
        sector: profile["sector"],
        industry: profile["industry"],
        exchange: profile["exchangeShortName"] || profile["exchange"],
        currency: profile["currency"],
        country: profile["country"],
        market_cap: safe_decimal(profile["mktCap"]),
        pe_ratio: safe_decimal(profile["pe"]),
        book_value: nil,
        eps: safe_decimal(profile["eps"]),
        dividend_per_share: safe_decimal(profile["lastDiv"]),
        dividend_yield: nil,
        profit_margin: nil,
        operating_margin: nil,
        return_on_equity: nil,
        return_on_assets: nil,
        revenue_ttm: nil,
        gross_profit_ttm: nil,
        ebitda: nil,
        revenue_per_share: nil,
        beta: safe_decimal(profile["beta"]),
        shares_outstanding: nil,
        ev_to_revenue: nil,
        ev_to_ebitda: nil,
        price_to_sales: nil,
        price_to_book: nil,
        fifty_two_week_high: safe_decimal(profile["range"]&.split("-")&.last),
        fifty_two_week_low: safe_decimal(profile["range"]&.split("-")&.first),
        analyst_target_price: safe_decimal(profile["dcf"]),
        quarterly_earnings_growth: nil,
        quarterly_revenue_growth: nil,
        forward_pe: nil,
        peg_ratio: nil
      })
    end

    # FMP returns "None" or empty strings for missing values.
    def safe_decimal(value)
      return nil if value.blank? || value == "None" || value == "-"
      BigDecimal(value.to_s)
    rescue ArgumentError
      nil
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
      key = KeyRotation.next_key_for(PROVIDER)
      raise ApiKeyNotConfiguredError.new(PROVIDER) if key.blank?
      key
    rescue ActiveRecord::Encryption::Errors::Decryption
      raise ApiKeyNotConfiguredError.new(PROVIDER, reason: "decryption failed")
    end
    end
  end
end
