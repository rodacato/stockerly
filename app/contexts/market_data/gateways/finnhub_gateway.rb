module MarketData
  module Gateways
    # Driven adapter: Finnhub REST API for US stock prices, historical candles, and ticker search.
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
