# Driven adapter: Yahoo Finance API for BMV (Mexican) stock/ETF prices and market indices.
# Uses the v8/finance/chart endpoint on query2 (the v8/finance/quote endpoint is deprecated).
class YahooFinanceGateway < MarketDataGateway
  include Dry::Monads[:result]

  BASE_URL = "https://query2.finance.yahoo.com"
  TIMEOUT  = 5

  # Yahoo Finance symbols → our internal MarketIndex symbols
  INDEX_SYMBOL_MAP = {
    "^GSPC" => "SPX",
    "^IXIC" => "NDX",
    "^DJI"  => "DJI",
    "^FTSE" => "UKX",
    "^MXX"  => "IPC",
    "^VIX"  => "VIX"
  }.freeze

  def initialize(api_key: nil)
    # Yahoo Finance v8 does not require an API key
  end

  # Fetch latest quote for a single symbol (e.g. "GENIUSSACV.MX").
  # Returns Success({ symbol:, price:, change_percent:, volume: })
  def fetch_price(symbol)
    result = fetch_chart(symbol)
    return result if result.failure?

    meta = result.value!
    Success({
      symbol: symbol,
      price: meta["regularMarketPrice"].to_d,
      change_percent: compute_change_percent(meta),
      volume: meta["regularMarketVolume"]&.to_i
    })
  end

  # Fetch prices for multiple symbols (one chart call per symbol).
  # Returns Success([{ symbol:, price:, ... }, ...])
  def fetch_bulk_prices(symbols)
    results = []
    last_error = nil

    symbols.each do |symbol|
      result = fetch_chart(symbol)

      if result.failure?
        last_error = result
        next
      end

      meta = result.value!
      results << {
        symbol: symbol,
        price: meta["regularMarketPrice"].to_d,
        change_percent: compute_change_percent(meta),
        volume: meta["regularMarketVolume"]&.to_i
      }
    end

    return last_error if results.empty? && last_error

    Success(results)
  rescue Faraday::Error => e
    Failure([ :gateway_error, e.message ])
  end

  # Fetch quotes for market indices (S&P 500, NASDAQ, DOW, FTSE, IPC, VIX).
  # Returns Success([{ symbol:, name:, value:, change_percent:, is_open: }, ...])
  def fetch_index_quotes(symbols = INDEX_SYMBOL_MAP.keys)
    quotes = []
    last_error = nil

    symbols.each do |yahoo_sym|
      result = fetch_chart(yahoo_sym)

      if result.failure?
        last_error = result
        next
      end

      meta = result.value!
      our_sym = INDEX_SYMBOL_MAP[yahoo_sym] || yahoo_sym

      quotes << {
        symbol: our_sym,
        name: meta["shortName"] || meta["longName"] || our_sym,
        value: meta["regularMarketPrice"].to_d,
        change_percent: compute_change_percent(meta),
        is_open: market_open?(meta)
      }
    end

    return last_error if quotes.empty? && last_error
    return Failure([ :not_found, "No index data returned" ]) if quotes.empty?

    Success(quotes)
  rescue Faraday::Error => e
    Failure([ :gateway_error, e.message ])
  end

  private

  def fetch_chart(symbol)
    response = connection.get("/v8/finance/chart/#{ERB::Util.url_encode(symbol)}") do |req|
      req.params["range"] = "1d"
      req.params["interval"] = "1d"
    end

    return Failure([ :rate_limited, "Yahoo Finance rate limit exceeded" ]) if response.status == 429
    return Failure([ :gateway_error, "Yahoo Finance returned #{response.status}" ]) unless response.success?

    meta = response.body.dig("chart", "result", 0, "meta")
    return Failure([ :not_found, "No data for #{symbol}" ]) unless meta

    Success(meta)
  rescue Faraday::Error => e
    Failure([ :gateway_error, e.message ])
  end

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                        retry_statuses: [ 500, 502, 503 ]
      f.headers["User-Agent"] = "Mozilla/5.0"
      f.response :json
      f.options.timeout = TIMEOUT
      f.options.open_timeout = TIMEOUT
    end
  end

  def compute_change_percent(meta)
    price = meta["regularMarketPrice"]&.to_d
    prev  = meta["chartPreviousClose"]&.to_d
    return BigDecimal("0") if prev.nil? || prev.zero?

    ((price - prev) / prev * 100).round(4)
  end

  def market_open?(meta)
    trading = meta.dig("currentTradingPeriod", "regular")
    return false unless trading

    now = Time.current.to_i
    now >= trading["start"].to_i && now <= trading["end"].to_i
  end
end
