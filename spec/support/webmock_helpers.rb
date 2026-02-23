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

  def stub_polygon_historical(symbol, days: 7)
    bars = days.times.map do |i|
      date = (days - i).days.ago
      {
        "t" => (date.to_time.to_i * 1000),
        "o" => 180.0 + i,
        "h" => 185.0 + i,
        "l" => 178.0 + i,
        "c" => 183.0 + i,
        "v" => 50_000_000 + (i * 1_000_000)
      }
    end

    stub_request(:get, %r{api\.polygon\.io/v2/aggs/ticker/#{symbol}/range/1/day/})
      .with(query: hash_including("apiKey"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { results: bars, resultsCount: bars.size }.to_json
      )
  end

  def stub_polygon_historical_empty(symbol)
    stub_request(:get, %r{api\.polygon\.io/v2/aggs/ticker/#{symbol}/range/1/day/})
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

  def stub_coingecko_historical(coin_id: "bitcoin", days: 7)
    prices = days.times.map do |i|
      timestamp_ms = (days - i).days.ago.to_i * 1000
      [timestamp_ms, 60_000.0 + (i * 500)]
    end

    stub_request(:get, "https://api.coingecko.com/api/v3/coins/#{coin_id}/market_chart")
      .with(query: hash_including("vs_currency" => "usd"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { prices: prices }.to_json
      )
  end

  def stub_coingecko_historical_empty(coin_id: "bitcoin")
    stub_request(:get, "https://api.coingecko.com/api/v3/coins/#{coin_id}/market_chart")
      .with(query: hash_including("vs_currency" => "usd"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { prices: [] }.to_json
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

  # --- Yahoo Finance ---

  def stub_yahoo_finance_price(symbol, price: 25.50, change_percent: 1.25, volume: 500_000)
    stub_request(:get, "https://query1.finance.yahoo.com/v8/finance/quote")
      .with(query: hash_including("symbols" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          quoteResponse: {
            result: [{
              "symbol" => symbol,
              "regularMarketPrice" => price,
              "regularMarketChangePercent" => change_percent,
              "regularMarketVolume" => volume
            }],
            error: nil
          }
        }.to_json
      )
  end

  def stub_yahoo_finance_bulk(symbols_data)
    results = symbols_data.map do |sym, data|
      { "symbol" => sym, "regularMarketPrice" => data[:price],
        "regularMarketChangePercent" => data[:change_percent] || 0,
        "regularMarketVolume" => data[:volume] || 0 }
    end

    stub_request(:get, "https://query1.finance.yahoo.com/v8/finance/quote")
      .with(query: hash_including("symbols"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { quoteResponse: { result: results, error: nil } }.to_json
      )
  end

  def stub_yahoo_finance_not_found(symbol)
    stub_request(:get, "https://query1.finance.yahoo.com/v8/finance/quote")
      .with(query: hash_including("symbols" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { quoteResponse: { result: [], error: nil } }.to_json
      )
  end

  def stub_yahoo_finance_rate_limited
    stub_request(:get, %r{query1\.finance\.yahoo\.com/v8/finance/quote})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_yahoo_finance_server_error
    stub_request(:get, %r{query1\.finance\.yahoo\.com/v8/finance/quote})
      .to_return(status: 500, body: "Internal Server Error")
  end

  # --- Crypto Fear & Greed (Alternative.me) ---

  def stub_crypto_fear_greed(value: 25, classification: "Extreme Fear")
    stub_request(:get, "https://api.alternative.me/fng/")
      .with(query: hash_including("limit" => "1"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          data: [{
            "value" => value.to_s,
            "value_classification" => classification,
            "timestamp" => Time.current.to_i.to_s
          }]
        }.to_json
      )
  end

  def stub_crypto_fear_greed_rate_limited
    stub_request(:get, %r{api\.alternative\.me/fng/})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_crypto_fear_greed_server_error
    stub_request(:get, %r{api\.alternative\.me/fng/})
      .to_return(status: 500, body: "Internal Server Error")
  end

  # --- Stock Fear & Greed (CNN) ---

  def stub_stock_fear_greed(score: 62, rating: "Greed")
    stub_request(:get, %r{production\.dataviz\.cnn\.io/index/fearandgreed/graphdata/})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          fear_and_greed: { "score" => score, "rating" => rating },
          market_momentum_sp500: { "score" => 71.2, "rating" => "Greed" },
          stock_price_strength: { "score" => 55.0, "rating" => "Neutral" },
          stock_price_breadth: { "score" => 48.3, "rating" => "Neutral" },
          put_call_options: { "score" => 65.1, "rating" => "Greed" },
          market_volatility_vix: { "score" => 80.0, "rating" => "Extreme Greed" },
          junk_bond_demand: { "score" => 52.0, "rating" => "Neutral" },
          safe_haven_demand: { "score" => 60.5, "rating" => "Greed" }
        }.to_json
      )
  end

  def stub_stock_fear_greed_rate_limited
    stub_request(:get, %r{production\.dataviz\.cnn\.io/index/fearandgreed/graphdata/})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_stock_fear_greed_server_error
    stub_request(:get, %r{production\.dataviz\.cnn\.io/index/fearandgreed/graphdata/})
      .to_return(status: 500, body: "Internal Server Error")
  end

  # --- ExchangeRate API ---

  def stub_fx_rates(base: "USD", rates: { "EUR" => 0.92, "MXN" => 17.25, "GBP" => 0.79 })
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
