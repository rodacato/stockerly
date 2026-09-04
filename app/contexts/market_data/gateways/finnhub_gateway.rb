module MarketData
  module Gateways
    # Driven adapter: Finnhub REST API for US stock prices, historical candles,
    # ticker search, company news, and earnings calendar.
    # Docs: https://finnhub.io/docs/api
    class FinnhubGateway < MarketDataGateway
    include PerformsRequests
    include ResolvesApiKey
    include Dry::Monads[:result]

    BASE_URL = "https://finnhub.io"
    PROVIDER = "Finnhub"
    TIMEOUT  = 5

    def initialize(api_key: nil)
      @api_key = api_key || resolve_api_key
    end

    # Fetch real-time quote for a single symbol.
    # Returns Success({ symbol:, price:, volume: })
    def fetch_price(symbol)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      result = get_json("/api/v1/quote", { symbol: symbol, token: @api_key })
      return result if result.failure?

      parse_quote(symbol, result.value!)
    end

    # Fetch prices for multiple symbols via individual calls.
    # Returns Success([{ symbol:, price:, ... }, ...])
    def fetch_bulk_prices(symbols)
      results = symbols.filter_map do |symbol|
        result = fetch_price(symbol)
        result.value! if result.success?
      end

      Success(results)
    end

    # Fetch daily OHLCV candles for a date range.
    # Returns Success([{ date:, open:, high:, low:, close:, volume: }, ...])
    def fetch_historical(symbol, from_date, to_date)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      from_ts = Date.parse(from_date.to_s).to_time.to_i
      to_ts   = Date.parse(to_date.to_s).to_time.to_i

      result = get_json("/api/v1/stock/candle", {
        symbol: symbol, resolution: "D", from: from_ts, to: to_ts, token: @api_key
      })
      return result if result.failure?

      parse_candles(result.value!)
    end

    # Fetch recent company news for a specific ticker.
    # Returns Success([{ title:, summary:, source:, url:, image_url:, published_at:, related_ticker: }, ...])
    def fetch_news(ticker: nil, limit: 20)
      return Failure([ :not_supported, "Finnhub requires a ticker for news" ]) if ticker.blank?

      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      from_date = 7.days.ago.to_date.to_s
      to_date = Date.current.to_s

      result = get_json("/api/v1/company-news", {
        symbol: ticker, from: from_date, to: to_date, token: @api_key
      })
      return result if result.failure?

      parse_news(result.value!, limit: limit)
    end

    # Fetch earnings calendar for a ticker.
    # Returns Success([{ report_date:, fiscal_quarter:, fiscal_year:, estimated_eps:, actual_eps:, timing: }, ...])
    def fetch_earnings(ticker)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      from_date = 6.months.ago.to_date.to_s
      to_date = (Date.current + 6.months).to_s

      result = get_json("/api/v1/calendar/earnings", {
        symbol: ticker, from: from_date, to: to_date, token: @api_key
      })
      return result if result.failure?

      parse_earnings(result.value!)
    end

    # Search tickers by name or symbol.
    # Returns Success([{ symbol:, name:, display_symbol:, type: }, ...])
    def search_tickers(query)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      result = get_json("/api/v1/search", { q: query, token: @api_key })
      return result if result.failure?

      parse_search(result.value!)
    end

    private

    def connection
      build_connection(url: BASE_URL, timeout: TIMEOUT, retry_options: { max: 2, interval: 0.5, backoff_factor: 2, retry_statuses: [ 500, 502, 503 ] })
    end

    def parse_quote(symbol, body)
      current = body["c"]
      return Failure([ :not_found, "No data for #{symbol}" ]) if current.nil? || current.zero?

      Success({
        symbol: symbol,
        price: current.to_d,
        volume: nil
      })
    end

    def parse_candles(body)
      return Failure([ :not_found, "No historical data returned" ]) if body["s"] != "ok"

      closes = body["c"] || []
      return Failure([ :not_found, "No historical data returned" ]) if closes.empty?

      bars = closes.each_with_index.map do |_close, i|
        {
          date: Time.at(body["t"][i]).utc.to_date,
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
        next if item["headline"].blank?

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
        next if item["date"].blank?

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
    end
  end
end
