module MarketData
  module Gateways
    # Driven adapter: Finnhub REST API for US stock prices, historical candles,
    # ticker search, company news, and earnings calendar.
    # Docs: https://finnhub.io/docs/api
    class FinnhubGateway < MarketDataGateway
    include Dry::Monads[:result]

    BASE_URL = "https://finnhub.io/api/v1"
    PROVIDER = "Finnhub"
    TIMEOUT  = 5

    def initialize(api_key: nil)
      @api_key = api_key || resolve_api_key
    end

    # Fetch real-time quote for a single symbol.
    # Returns Success({ symbol:, price:, change_percent:, volume: })
    def fetch_price(symbol)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("/api/v1/quote") do |req|
        req.params["symbol"] = symbol
        req.params["token"] = @api_key
      end

      return Failure([ :rate_limited, "Finnhub rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "Finnhub returned #{response.status}" ]) unless response.success?

      parse_quote(symbol, response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Fetch prices for multiple symbols via individual calls.
    # Returns Success([{ symbol:, price:, ... }, ...])
    def fetch_bulk_prices(symbols)
      results = symbols.filter_map do |symbol|
        result = fetch_price(symbol)
        result.value! if result.success?
      end

      Success(results)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Fetch daily OHLCV candles for a date range.
    # Returns Success([{ date:, open:, high:, low:, close:, volume: }, ...])
    def fetch_historical(symbol, from_date, to_date)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      from_ts = Date.parse(from_date.to_s).to_time.to_i
      to_ts   = Date.parse(to_date.to_s).to_time.to_i

      response = connection.get("/api/v1/stock/candle") do |req|
        req.params["symbol"] = symbol
        req.params["resolution"] = "D"
        req.params["from"] = from_ts
        req.params["to"] = to_ts
        req.params["token"] = @api_key
      end

      return Failure([ :rate_limited, "Finnhub rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "Finnhub returned #{response.status}" ]) unless response.success?

      parse_candles(response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Fetch recent company news for a specific ticker.
    # Returns Success([{ title:, summary:, source:, url:, image_url:, published_at:, related_ticker: }, ...])
    def fetch_news(ticker: nil, limit: 20)
      return Failure([ :not_supported, "Finnhub requires a ticker for news" ]) if ticker.blank?

      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      from_date = 7.days.ago.to_date.to_s
      to_date = Date.current.to_s

      response = connection.get("/api/v1/company-news") do |req|
        req.params["symbol"] = ticker
        req.params["from"] = from_date
        req.params["to"] = to_date
        req.params["token"] = @api_key
      end

      return Failure([ :rate_limited, "Finnhub rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "Finnhub returned #{response.status}" ]) unless response.success?

      parse_news(response.body, limit: limit)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Fetch earnings calendar for a ticker.
    # Returns Success([{ report_date:, fiscal_quarter:, fiscal_year:, estimated_eps:, actual_eps:, timing: }, ...])
    def fetch_earnings(ticker)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      from_date = 6.months.ago.to_date.to_s
      to_date = (Date.current + 6.months).to_s

      response = connection.get("/api/v1/calendar/earnings") do |req|
        req.params["symbol"] = ticker
        req.params["from"] = from_date
        req.params["to"] = to_date
        req.params["token"] = @api_key
      end

      return Failure([ :rate_limited, "Finnhub rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "Finnhub returned #{response.status}" ]) unless response.success?

      parse_earnings(response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Search tickers by name or symbol.
    # Returns Success([{ symbol:, name:, display_symbol:, type: }, ...])
    def search_tickers(query)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("/api/v1/search") do |req|
        req.params["q"] = query
        req.params["token"] = @api_key
      end

      return Failure([ :rate_limited, "Finnhub rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "Finnhub returned #{response.status}" ]) unless response.success?

      parse_search(response.body)
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

    def parse_quote(symbol, body)
      current = body["c"]
      return Failure([ :not_found, "No data for #{symbol}" ]) if current.nil? || current.zero?

      Success({
        symbol: symbol,
        price: current.to_d,
        change_percent: body["dp"]&.to_d || BigDecimal("0"),
        volume: nil
      })
    end

    def parse_candles(body)
      return Failure([ :not_found, "No historical data returned" ]) if body["s"] != "ok"

      closes = body["c"] || []
      return Failure([ :not_found, "No historical data returned" ]) if closes.empty?

      bars = closes.each_with_index.map do |_close, i|
        {
          date: Time.at(body["t"][i]).to_date,
          open: body["o"][i].to_d,
          high: body["h"][i].to_d,
          low: body["l"][i].to_d,
          close: body["c"][i].to_d,
          volume: body["v"][i]&.to_i
        }
      end

      Success(bars)
    end

    def parse_news(body, limit: 20)
      results = Array(body).first(limit)
      return Success([]) if results.blank?

      articles = results.filter_map do |item|
        next unless item["headline"].present?

        {
          title: item["headline"],
          summary: item["summary"],
          source: item["source"] || "Finnhub",
          url: item["url"],
          image_url: item["image"],
          published_at: item["datetime"] ? Time.at(item["datetime"]).in_time_zone : nil,
          related_ticker: item["related"]&.split(",")&.first
        }
      end

      Success(articles)
    end

    def parse_earnings(body)
      results = body.dig("earningsCalendar") || []
      return Success([]) if results.blank?

      events = results.filter_map do |item|
        next unless item["date"].present?

        {
          report_date: Date.parse(item["date"]),
          fiscal_quarter: item["quarter"]&.to_i,
          fiscal_year: item["year"]&.to_i,
          estimated_eps: item["epsEstimate"]&.to_d,
          actual_eps: item["epsActual"]&.to_d,
          timing: item["hour"] == "bmo" ? :before_market_open : :after_market_close
        }
      end

      Success(events)
    end

    def parse_search(body)
      results = body["result"] || []

      parsed = results.filter_map do |r|
        next if r["symbol"].blank?

        {
          symbol: r["symbol"],
          name: r["description"],
          display_symbol: r["displaySymbol"],
          type: r["type"]
        }
      end

      Success(parsed)
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
