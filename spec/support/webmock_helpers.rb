# Shared WebMock stubs for external API gateways.
module WebmockHelpers
  # --- Polygon.io ---

  def stub_polygon_price(symbol, close: 189.43, open: 185.00, volume: 58_200_000)
    stub_request(:get, "https://api.polygon.io/v2/aggs/ticker/#{symbol}/prev")
      .with(query: hash_including("apiKey"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          results: [{ "T" => symbol, "c" => close, "o" => open, "h" => close + 2, "l" => open - 1, "v" => volume }],
          resultsCount: 1
        }.to_json
      )
  end

  def stub_polygon_not_found(symbol)
    stub_request(:get, "https://api.polygon.io/v2/aggs/ticker/#{symbol}/prev")
      .with(query: hash_including("apiKey"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { results: [], resultsCount: 0 }.to_json
      )
  end

  def stub_polygon_rate_limited
    stub_request(:get, %r{api\.polygon\.io/v2/aggs/ticker/.+/prev})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_polygon_server_error
    stub_request(:get, %r{api\.polygon\.io/v2/aggs/ticker/.+/prev})
      .to_return(status: 500, body: "Internal Server Error")
  end

  # --- CoinGecko ---

  def stub_coingecko_prices(data = {})
    default = {
      "bitcoin" => { "usd" => 64_231.0, "usd_24h_change" => 0.85, "usd_market_cap" => 1_260_000_000_000 },
      "ethereum" => { "usd" => 3_450.0, "usd_24h_change" => -0.45, "usd_market_cap" => 415_000_000_000 }
    }
    body = default.merge(data)

    stub_request(:get, "https://api.coingecko.com/api/v3/simple/price")
      .with(query: hash_including("ids", "vs_currencies"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: body.to_json
      )
  end

  def stub_coingecko_rate_limited
    stub_request(:get, %r{api\.coingecko\.com/api/v3/simple/price})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_coingecko_server_error
    stub_request(:get, %r{api\.coingecko\.com/api/v3/simple/price})
      .to_return(status: 500, body: "Internal Server Error")
  end

  # --- ExchangeRate API ---

  def stub_fx_rates(base: "USD", rates: { "EUR" => 0.92, "MXN" => 17.25, "GBP" => 0.79, "TWD" => 31.50 })
    stub_request(:get, %r{v6\.exchangerate-api\.com/v6/.*/latest/#{base}})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { result: "success", base_code: base, conversion_rates: rates }.to_json
      )
  end

  def stub_fx_rates_rate_limited
    stub_request(:get, %r{v6\.exchangerate-api\.com/v6/.*/latest})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_fx_rates_server_error
    stub_request(:get, %r{v6\.exchangerate-api\.com/v6/.*/latest})
      .to_return(status: 500, body: "Internal Server Error")
  end
end

RSpec.configure do |config|
  config.include WebmockHelpers
end
