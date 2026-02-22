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

  def calculate_change_percent(open, close)
    return 0 if open.nil? || open.zero?
    ((close.to_d - open.to_d) / open.to_d * 100).round(4)
  end

  def resolve_api_key
    Integration.find_by(provider_name: "Polygon.io")&.api_key_encrypted ||
      Rails.application.credentials.dig(:polygon, :api_key) ||
      ""
  end
end
