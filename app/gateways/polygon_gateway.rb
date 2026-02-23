# Driven adapter: Polygon.io REST API for stock/index prices.
# Docs: https://polygon.io/docs/stocks/get_v2_aggs_ticker__stocksticker__prev
class PolygonGateway < MarketDataGateway
  include Dry::Monads[:result]

  BASE_URL = "https://api.polygon.io"
  TIMEOUT  = 5

  def initialize(api_key: nil)
    @api_key = api_key || resolve_api_key
  end

  # Fetch previous-day close for a single symbol.
  # Returns Success({ symbol:, price:, change_percent:, volume: })
  def fetch_price(symbol)
    response = connection.get("/v2/aggs/ticker/#{symbol}/prev") do |req|
      req.params["apiKey"] = @api_key
    end

    return Failure([:rate_limited, "Polygon.io rate limit exceeded"]) if response.status == 429
    return Failure([:gateway_error, "Polygon.io returned #{response.status}"]) unless response.success?

    parse_single(symbol, response.body)
  rescue Faraday::Error => e
    Failure([:gateway_error, e.message])
  end

  # Fetch daily OHLCV for a date range.
  # Returns Success([{ date:, open:, high:, low:, close:, volume: }, ...])
  def fetch_historical(symbol, from_date, to_date)
    response = connection.get("/v2/aggs/ticker/#{symbol}/range/1/day/#{from_date}/#{to_date}") do |req|
      req.params["apiKey"] = @api_key
      req.params["adjusted"] = "true"
      req.params["sort"] = "asc"
    end

    return Failure([:rate_limited, "Polygon.io rate limit exceeded"]) if response.status == 429
    return Failure([:gateway_error, "Polygon.io returned #{response.status}"]) unless response.success?

    parse_historical(response.body)
  rescue Faraday::Error => e
    Failure([:gateway_error, e.message])
  end

  # Fetch recent news articles.
  # Returns Success([{ title:, summary:, source:, url:, image_url:, published_at:, related_ticker: }, ...])
  def fetch_news(ticker: nil, limit: 20)
    response = connection.get("/v2/reference/news") do |req|
      req.params["apiKey"] = @api_key
      req.params["limit"] = limit
      req.params["order"] = "desc"
      req.params["sort"] = "published_utc"
      req.params["ticker"] = ticker if ticker.present?
    end

    return Failure([:rate_limited, "Polygon.io rate limit exceeded"]) if response.status == 429
    return Failure([:gateway_error, "Polygon.io returned #{response.status}"]) unless response.success?

    parse_news(response.body)
  rescue Faraday::Error => e
    Failure([:gateway_error, e.message])
  end

  # Fetch prices for multiple symbols via individual calls.
  # Returns Success([{ symbol:, price:, ... }, ...])
  def fetch_bulk_prices(symbols)
    results = symbols.filter_map do |symbol|
      case fetch_price(symbol)
      in Success(data) then data
      in Failure(_) then nil
      end
    end

    Success(results)
  rescue Faraday::Error => e
    Failure([:gateway_error, e.message])
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :retry, max: 2, interval: 0.5, backoff_factor: 2,
                        retry_statuses: [500, 502, 503]
      f.response :json
      f.options.timeout = TIMEOUT
      f.options.open_timeout = TIMEOUT
    end
  end

  def parse_single(symbol, body)
    result = body.dig("results", 0)
    return Failure([:not_found, "No data for #{symbol}"]) unless result

    Success({
      symbol: symbol,
      price: result["c"].to_d,
      change_percent: calculate_change_percent(result["o"], result["c"]),
      volume: result["v"]&.to_i
    })
  end

  def parse_historical(body)
    results = body["results"]
    return Failure([:not_found, "No historical data returned"]) if results.blank?

    bars = results.map do |bar|
      {
        date: Time.at(bar["t"] / 1000).to_date,
        open: bar["o"].to_d,
        high: bar["h"].to_d,
        low: bar["l"].to_d,
        close: bar["c"].to_d,
        volume: bar["v"]&.to_i
      }
    end

    Success(bars)
  end

  def parse_news(body)
    results = body["results"]
    return Success([]) if results.blank?

    articles = results.filter_map do |item|
      next unless item["title"].present?

      {
        title: item["title"],
        summary: item["description"],
        source: item.dig("publisher", "name") || "Polygon",
        url: item["article_url"],
        image_url: item["image_url"],
        published_at: Time.zone.parse(item["published_utc"]),
        related_ticker: item.dig("tickers", 0)
      }
    end

    Success(articles)
  end

  def calculate_change_percent(open, close)
    return 0 if open.nil? || open.zero?
    ((close.to_d - open.to_d) / open.to_d * 100).round(4)
  end

  def resolve_api_key
    Integration.find_by(provider_name: "Polygon.io")&.api_key_encrypted ||
      ENV.fetch("POLYGON_API_KEY", "")
  end
end
