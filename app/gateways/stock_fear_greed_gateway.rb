# Fetches the CNN Fear & Greed Index for stocks.
# Undocumented API — requires User-Agent header.
# Returns a composite score (0-100) with 7 sub-indicators.
class StockFearGreedGateway
  include Dry::Monads[:result]

  BASE_URL = "https://production.dataviz.cnn.io"
  TIMEOUT  = 10

  def fetch_index
    date = Time.current.strftime("%Y-%m-%d")
    response = connection.get("/index/fearandgreed/graphdata/#{date}")

    return Failure([ :rate_limited, "CNN API rate limit exceeded" ]) if response.status == 429
    return Failure([ :gateway_error, "CNN API returned #{response.status}" ]) unless response.success?

    parse(response.body)
  rescue Faraday::Error => e
    Failure([ :gateway_error, e.message ])
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.options.timeout = TIMEOUT
      f.options.open_timeout = TIMEOUT
      f.headers["User-Agent"] = "Mozilla/5.0 (compatible; Stockerly/1.0)"
      f.request :retry, max: 2, interval: 1.0
      f.response :json
      f.adapter Faraday.default_adapter
    end
  end

  def parse(body)
    fg = body["fear_and_greed"]
    return Failure([ :parse_error, "No fear_and_greed in CNN response" ]) unless fg

    component_data = extract_components(body)

    Success({
      value: fg["score"].to_i,
      classification: fg["rating"],
      fetched_at: Time.current,
      component_data: component_data
    })
  rescue StandardError => e
    Failure([ :parse_error, "Failed to parse CNN response: #{e.message}" ])
  end

  def extract_components(body)
    indicators = %w[
      market_momentum_sp500 stock_price_strength stock_price_breadth
      put_call_options market_volatility_vix junk_bond_demand
      safe_haven_demand
    ]

    indicators.each_with_object({}) do |key, hash|
      if body[key]
        hash[key] = {
          score: body[key]["score"]&.to_f,
          rating: body[key]["rating"]
        }
      end
    end
  end
end
