# Driven adapter: Yahoo Finance API for BMV (Mexican) stock/ETF prices.
# Endpoint: https://query1.finance.yahoo.com/v8/finance/quote?symbols=SYMBOL
class YahooFinanceGateway < MarketDataGateway
  include Dry::Monads[:result]

  BASE_URL = "https://query1.finance.yahoo.com"
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
    response = connection.get("/v8/finance/quote") do |req|
      req.params["symbols"] = symbol
    end

    return Failure([ :rate_limited, "Yahoo Finance rate limit exceeded" ]) if response.status == 429
    return Failure([ :gateway_error, "Yahoo Finance returned #{response.status}" ]) unless response.success?

    parse_single(symbol, response.body)
  rescue Faraday::Error => e
    Failure([ :gateway_error, e.message ])
  end

  # Fetch prices for multiple symbols in a single API call.
  # Returns Success([{ symbol:, price:, ... }, ...])
  def fetch_bulk_prices(symbols)
    response = connection.get("/v8/finance/quote") do |req|
      req.params["symbols"] = symbols.join(",")
    end

    return Failure([ :rate_limited, "Yahoo Finance rate limit exceeded" ]) if response.status == 429
    return Failure([ :gateway_error, "Yahoo Finance returned #{response.status}" ]) unless response.success?

    parse_bulk(response.body)
  rescue Faraday::Error => e
    Failure([ :gateway_error, e.message ])
  end

  # Fetch quotes for market indices (S&P 500, NASDAQ, DOW, FTSE, IPC, VIX).
  # Returns Success([{ symbol:, name:, value:, change_percent:, is_open: }, ...])
  def fetch_index_quotes(symbols = INDEX_SYMBOL_MAP.keys)
    response = connection.get("/v8/finance/quote") do |req|
      req.params["symbols"] = symbols.join(",")
    end

    return Failure([ :rate_limited, "Yahoo Finance rate limit exceeded" ]) if response.status == 429
    return Failure([ :gateway_error, "Yahoo Finance returned #{response.status}" ]) unless response.success?

    parse_index_quotes(response.body)
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

  def parse_single(symbol, body)
    result = body.dig("quoteResponse", "result", 0)
    return Failure([ :not_found, "No data for #{symbol}" ]) unless result

    Success({
      symbol: symbol,
      price: result["regularMarketPrice"].to_d,
      change_percent: result["regularMarketChangePercent"]&.to_d&.round(4) || 0,
      volume: result["regularMarketVolume"]&.to_i
    })
  end

  def parse_index_quotes(body)
    results_array = body.dig("quoteResponse", "result") || []
    return Failure([ :not_found, "No index data returned" ]) if results_array.empty?

    quotes = results_array.filter_map do |result|
      yahoo_sym = result["symbol"]
      our_sym = INDEX_SYMBOL_MAP[yahoo_sym] || yahoo_sym
      next unless result["regularMarketPrice"]

      {
        symbol: our_sym,
        name: result["shortName"] || result["longName"] || our_sym,
        value: result["regularMarketPrice"].to_d,
        change_percent: result["regularMarketChangePercent"]&.to_d&.round(4) || 0,
        is_open: result["marketState"] == "REGULAR"
      }
    end

    Success(quotes)
  end

  def parse_bulk(body)
    results_array = body.dig("quoteResponse", "result") || []

    results = results_array.filter_map do |result|
      next unless result["regularMarketPrice"]

      {
        symbol: result["symbol"],
        price: result["regularMarketPrice"].to_d,
        change_percent: result["regularMarketChangePercent"]&.to_d&.round(4) || 0,
        volume: result["regularMarketVolume"]&.to_i
      }
    end

    Success(results)
  end
end
