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
          results: [ { "T" => symbol, "c" => close, "o" => open, "h" => close + 2, "l" => open - 1, "v" => volume } ],
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

  def stub_polygon_news(count: 3)
    articles = count.times.map do |i|
      {
        "title" => "Article #{i + 1}",
        "description" => "Summary for article #{i + 1}",
        "publisher" => { "name" => "Bloomberg" },
        "article_url" => "https://example.com/article-#{i + 1}",
        "image_url" => "https://example.com/image-#{i + 1}.jpg",
        "published_utc" => (i + 1).hours.ago.utc.iso8601,
        "tickers" => [ "AAPL" ]
      }
    end

    stub_request(:get, "https://api.polygon.io/v2/reference/news")
      .with(query: hash_including("apiKey"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { results: articles, count: articles.size }.to_json
      )
  end

  def stub_polygon_news_empty
    stub_request(:get, "https://api.polygon.io/v2/reference/news")
      .with(query: hash_including("apiKey"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { results: [], count: 0 }.to_json
      )
  end

  def stub_polygon_earnings(ticker, count: 2)
    events = count.times.map do |i|
      {
        "end_date" => (Date.current + (i + 1).months).to_s,
        "fiscal_quarter" => "Q#{i + 1}",
        "fiscal_year" => Date.current.year.to_s,
        "eps" => { "estimated" => (1.5 + i * 0.1).round(2), "actual" => nil },
        "timeframe" => i.even? ? "pre" : "post"
      }
    end

    stub_request(:get, "https://api.polygon.io/vX/reference/tickers/#{ticker}/earnings")
      .with(query: hash_including("apiKey"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { results: events, count: events.size }.to_json
      )
  end

  def stub_polygon_earnings_with_actuals(ticker, count: 2)
    events = count.times.map do |i|
      {
        "end_date" => (Date.current - (i + 1).months).to_s,
        "fiscal_quarter" => "Q#{i + 1}",
        "fiscal_year" => Date.current.year.to_s,
        "eps" => { "estimated" => (1.5 + i * 0.1).round(2), "actual" => (1.7 + i * 0.1).round(2) },
        "timeframe" => i.even? ? "pre" : "post"
      }
    end

    stub_request(:get, "https://api.polygon.io/vX/reference/tickers/#{ticker}/earnings")
      .with(query: hash_including("apiKey"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { results: events, count: events.size }.to_json
      )
  end

  def stub_polygon_earnings_empty(ticker)
    stub_request(:get, "https://api.polygon.io/vX/reference/tickers/#{ticker}/earnings")
      .with(query: hash_including("apiKey"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { results: [], count: 0 }.to_json
      )
  end

  def stub_polygon_earnings_rate_limited(ticker)
    stub_request(:get, "https://api.polygon.io/vX/reference/tickers/#{ticker}/earnings")
      .with(query: hash_including("apiKey"))
      .to_return(status: 429, body: "Rate limit exceeded")
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
      [ timestamp_ms, 60_000.0 + (i * 500) ]
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

  def stub_coingecko_markets(data = nil)
    default = [
      {
        "id" => "bitcoin", "symbol" => "btc", "current_price" => 67_250.0,
        "market_cap" => 1_310_000_000_000, "total_volume" => 28_400_000_000,
        "circulating_supply" => 19_600_000, "total_supply" => 21_000_000,
        "max_supply" => 21_000_000, "fully_diluted_valuation" => 1_080_000_000_000,
        "ath" => 73_750.0, "ath_change_percentage" => -8.81,
        "atl" => 67.81, "atl_change_percentage" => 99_089.0,
        "price_change_percentage_24h" => -0.45
      }
    ]
    body = data || default

    stub_request(:get, "https://api.coingecko.com/api/v3/coins/markets")
      .with(query: hash_including("vs_currency" => "usd"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: body.to_json
      )
  end

  def stub_coingecko_markets_rate_limited
    stub_request(:get, %r{api\.coingecko\.com/api/v3/coins/markets})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  # --- Yahoo Finance (v8/finance/chart on query2) ---

  def stub_yahoo_finance_price(symbol, price: 25.50, change_percent: 1.25, volume: 500_000)
    previous_close = (price / (1 + change_percent / 100.0)).round(2)
    stub_yahoo_chart(symbol, price: price, previous_close: previous_close, volume: volume)
  end

  def stub_yahoo_finance_bulk(symbols_data)
    # Stub batch endpoint with all symbols
    batch_results = symbols_data.map do |sym, data|
      { symbol: sym, regularMarketPrice: data[:price], regularMarketChangePercent: data[:change_percent] || 0, regularMarketVolume: data[:volume] || 0 }
    end
    stub_request(:get, %r{query1\.finance\.yahoo\.com/v7/finance/quote})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { quoteResponse: { result: batch_results } }.to_json
      )

    # Also stub individual chart calls for fallback
    symbols_data.each do |sym, data|
      change = data[:change_percent] || 0
      previous_close = (data[:price] / (1 + change / 100.0)).round(2)
      stub_yahoo_chart(sym, price: data[:price], previous_close: previous_close, volume: data[:volume] || 0)
    end
  end

  def stub_yahoo_batch_not_available
    stub_request(:get, %r{query1\.finance\.yahoo\.com/v7/finance/quote})
      .to_return(status: 404, body: "Not Found")
  end

  def stub_yahoo_finance_not_found(symbol)
    stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/#{Regexp.escape(symbol)}})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { chart: { result: nil, error: { code: "Not Found" } } }.to_json
      )
  end

  def stub_yahoo_finance_rate_limited
    stub_request(:get, %r{query1\.finance\.yahoo\.com/v7/finance/quote})
      .to_return(status: 429, body: "Rate limit exceeded")
    stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_yahoo_finance_server_error
    stub_request(:get, %r{query1\.finance\.yahoo\.com/v7/finance/quote})
      .to_return(status: 500, body: "Internal Server Error")
    stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/})
      .to_return(status: 500, body: "Internal Server Error")
  end

  def stub_yahoo_index_quotes(quotes_data)
    quotes_data.each do |yahoo_sym, data|
      value = data[:value]
      change = data[:change_percent] || 0
      previous_close = (value / (1 + change / 100.0)).round(2)
      now = Time.current.to_i

      regular_start = data[:is_open] ? now - 3600 : now + 3600
      regular_end   = data[:is_open] ? now + 3600 : now + 7200

      stub_yahoo_chart(yahoo_sym,
        price: value,
        previous_close: previous_close,
        volume: 0,
        short_name: data[:name] || yahoo_sym,
        regular_start: regular_start,
        regular_end: regular_end)
    end
  end

  def stub_yahoo_index_quotes_empty
    stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { chart: { result: nil, error: { code: "Not Found" } } }.to_json
      )
  end

  # --- Crypto Fear & Greed (Alternative.me) ---

  def stub_crypto_fear_greed(value: 25, classification: "Extreme Fear")
    stub_request(:get, "https://api.alternative.me/fng/")
      .with(query: hash_including("limit" => "1"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          data: [ {
            "value" => value.to_s,
            "value_classification" => classification,
            "timestamp" => Time.current.to_i.to_s
          } ]
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

  # --- Alpha Vantage (Fundamentals) ---

  def stub_alpha_vantage_overview(symbol, data = {})
    default = {
      "Symbol" => symbol,
      "Name" => "#{symbol} Inc.",
      "Description" => "Test company",
      "Sector" => "Technology",
      "Industry" => "Software",
      "Exchange" => "NASDAQ",
      "Currency" => "USD",
      "Country" => "USA",
      "MarketCapitalization" => "2940000000000",
      "PERatio" => "31.25",
      "ForwardPE" => "28.50",
      "PEGRatio" => "2.15",
      "BookValue" => "3.95",
      "EPS" => "6.07",
      "DividendPerShare" => "0.96",
      "DividendYield" => "0.0052",
      "ProfitMargin" => "0.2461",
      "OperatingMarginTTM" => "0.3031",
      "ReturnOnEquityTTM" => "1.5700",
      "ReturnOnAssetsTTM" => "0.2720",
      "RevenueTTM" => "391035000000",
      "GrossProfitTTM" => "170782000000",
      "EBITDA" => "131561000000",
      "RevenuePerShareTTM" => "25.23",
      "Beta" => "1.24",
      "SharesOutstanding" => "15500000000",
      "EVToRevenue" => "7.83",
      "EVToEBITDA" => "23.45",
      "PriceToSalesRatioTTM" => "7.52",
      "PriceToBookRatio" => "47.96",
      "52WeekHigh" => "199.62",
      "52WeekLow" => "164.08",
      "AnalystTargetPrice" => "200.00",
      "QuarterlyEarningsGrowthYOY" => "0.10",
      "QuarterlyRevenueGrowthYOY" => "0.05"
    }

    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: hash_including("function" => "OVERVIEW", "symbol" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: default.merge(data).to_json
      )
  end

  def stub_alpha_vantage_rate_limited(function = nil)
    query = function ? hash_including("function" => function) : hash_including("apikey")
    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: query)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { "Note" => "Thank you for using Alpha Vantage! Our standard API rate limit is 25 requests per day." }.to_json
      )
  end

  def stub_alpha_vantage_auth_error(function = nil)
    query = function ? hash_including("function" => function) : hash_including("apikey")
    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: query)
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { "Information" => "The API key is invalid or inactive." }.to_json
      )
  end

  def stub_alpha_vantage_not_found(symbol)
    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: hash_including("function" => "OVERVIEW", "symbol" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {}.to_json
      )
  end

  def stub_alpha_vantage_server_error(function = nil)
    query = function ? hash_including("function" => function) : hash_including("apikey")
    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: query)
      .to_return(status: 500, body: "Internal Server Error")
  end

  def stub_alpha_vantage_timeout(function = nil)
    query = function ? hash_including("function" => function) : hash_including("apikey")
    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: query)
      .to_timeout
  end

  # --- Alpha Vantage Financial Statements ---

  def stub_alpha_vantage_income_statement(symbol, data = {})
    default = {
      "symbol" => symbol,
      "annualReports" => [
        {
          "fiscalDateEnding" => "2023-09-30",
          "reportedCurrency" => "USD",
          "totalRevenue" => "383285000000",
          "grossProfit" => "169148000000",
          "operatingIncome" => "114301000000",
          "netIncome" => "96995000000",
          "ebitda" => "125820000000",
          "interestExpense" => "3933000000",
          "researchAndDevelopment" => "29915000000",
          "costOfRevenue" => "214137000000",
          "sellingGeneralAndAdministrative" => "24932000000"
        },
        {
          "fiscalDateEnding" => "2022-09-30",
          "reportedCurrency" => "USD",
          "totalRevenue" => "394328000000",
          "grossProfit" => "170782000000",
          "operatingIncome" => "119437000000",
          "netIncome" => "99803000000",
          "ebitda" => "130541000000",
          "interestExpense" => "2931000000",
          "researchAndDevelopment" => "26251000000",
          "costOfRevenue" => "223546000000",
          "sellingGeneralAndAdministrative" => "25094000000"
        }
      ],
      "quarterlyReports" => [
        { "fiscalDateEnding" => "2023-09-30", "reportedCurrency" => "USD",
          "totalRevenue" => "89498000000", "grossProfit" => "40427000000",
          "operatingIncome" => "26969000000", "netIncome" => "22956000000",
          "ebitda" => "30000000000", "interestExpense" => "1000000000" },
        { "fiscalDateEnding" => "2023-06-30", "reportedCurrency" => "USD",
          "totalRevenue" => "81797000000", "grossProfit" => "36413000000",
          "operatingIncome" => "23210000000", "netIncome" => "19881000000",
          "ebitda" => "27000000000", "interestExpense" => "998000000" },
        { "fiscalDateEnding" => "2023-03-31", "reportedCurrency" => "USD",
          "totalRevenue" => "94836000000", "grossProfit" => "42606000000",
          "operatingIncome" => "28318000000", "netIncome" => "24160000000",
          "ebitda" => "32000000000", "interestExpense" => "930000000" },
        { "fiscalDateEnding" => "2022-12-31", "reportedCurrency" => "USD",
          "totalRevenue" => "117154000000", "grossProfit" => "50702000000",
          "operatingIncome" => "35804000000", "netIncome" => "29998000000",
          "ebitda" => "39000000000", "interestExpense" => "1005000000" }
      ]
    }

    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: hash_including("function" => "INCOME_STATEMENT", "symbol" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: default.merge(data).to_json
      )
  end

  def stub_alpha_vantage_balance_sheet(symbol, data = {})
    default = {
      "symbol" => symbol,
      "annualReports" => [
        {
          "fiscalDateEnding" => "2023-09-30",
          "reportedCurrency" => "USD",
          "totalAssets" => "352583000000",
          "totalCurrentAssets" => "143566000000",
          "totalNonCurrentAssets" => "209017000000",
          "totalLiabilities" => "290437000000",
          "totalCurrentLiabilities" => "145308000000",
          "totalShareholderEquity" => "62146000000",
          "longTermDebt" => "95281000000",
          "shortTermDebt" => "15807000000",
          "inventory" => "6331000000",
          "cashAndShortTermInvestments" => "29965000000"
        },
        {
          "fiscalDateEnding" => "2022-09-30",
          "reportedCurrency" => "USD",
          "totalAssets" => "352755000000",
          "totalCurrentAssets" => "135405000000",
          "totalNonCurrentAssets" => "217350000000",
          "totalLiabilities" => "302083000000",
          "totalCurrentLiabilities" => "153982000000",
          "totalShareholderEquity" => "50672000000",
          "longTermDebt" => "98959000000",
          "shortTermDebt" => "11128000000",
          "inventory" => "4946000000",
          "cashAndShortTermInvestments" => "23646000000"
        }
      ],
      "quarterlyReports" => [
        { "fiscalDateEnding" => "2023-09-30", "reportedCurrency" => "USD",
          "totalAssets" => "352583000000", "totalCurrentAssets" => "143566000000",
          "totalCurrentLiabilities" => "145308000000", "totalShareholderEquity" => "62146000000",
          "longTermDebt" => "95281000000", "shortTermDebt" => "15807000000",
          "inventory" => "6331000000" }
      ]
    }

    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: hash_including("function" => "BALANCE_SHEET", "symbol" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: default.merge(data).to_json
      )
  end

  def stub_alpha_vantage_cash_flow(symbol, data = {})
    default = {
      "symbol" => symbol,
      "annualReports" => [
        {
          "fiscalDateEnding" => "2023-09-30",
          "reportedCurrency" => "USD",
          "operatingCashflow" => "110543000000",
          "capitalExpenditures" => "11000000000",
          "dividendPayout" => "15025000000",
          "netIncome" => "96995000000",
          "depreciationDepletionAndAmortization" => "11519000000",
          "changeInOperatingLiabilities" => "2000000000"
        },
        {
          "fiscalDateEnding" => "2022-09-30",
          "reportedCurrency" => "USD",
          "operatingCashflow" => "122151000000",
          "capitalExpenditures" => "10708000000",
          "dividendPayout" => "14841000000",
          "netIncome" => "99803000000",
          "depreciationDepletionAndAmortization" => "11104000000",
          "changeInOperatingLiabilities" => "5000000000"
        }
      ],
      "quarterlyReports" => [
        { "fiscalDateEnding" => "2023-09-30", "reportedCurrency" => "USD",
          "operatingCashflow" => "26000000000", "capitalExpenditures" => "2800000000",
          "dividendPayout" => "3800000000" },
        { "fiscalDateEnding" => "2023-06-30", "reportedCurrency" => "USD",
          "operatingCashflow" => "26400000000", "capitalExpenditures" => "2700000000",
          "dividendPayout" => "3750000000" },
        { "fiscalDateEnding" => "2023-03-31", "reportedCurrency" => "USD",
          "operatingCashflow" => "34000000000", "capitalExpenditures" => "2900000000",
          "dividendPayout" => "3750000000" },
        { "fiscalDateEnding" => "2022-12-31", "reportedCurrency" => "USD",
          "operatingCashflow" => "34143000000", "capitalExpenditures" => "3600000000",
          "dividendPayout" => "3725000000" }
      ]
    }

    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: hash_including("function" => "CASH_FLOW", "symbol" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: default.merge(data).to_json
      )
  end

  def stub_alpha_vantage_empty_statement(symbol, function)
    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: hash_including("function" => function, "symbol" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {}.to_json
      )
  end

  # --- Banxico SIE API (CETES) ---

  def stub_banxico_auctions(term: "28", yield_rate: 11.15, date: "25/02/2026")
    series_id = MarketData::BanxicoGateway::CETES_SERIES[term.to_s]
    stub_request(:get, "#{MarketData::BanxicoGateway::BASE_URL}series/#{series_id}/datos/oportuno")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          bmx: {
            series: [ {
              "idSerie" => series_id,
              "titulo" => "CETES #{term}D",
              "datos" => [ { "fecha" => date, "dato" => yield_rate.to_s } ]
            } ]
          }
        }.to_json
      )
  end

  def stub_banxico_not_found(term: "28")
    series_id = MarketData::BanxicoGateway::CETES_SERIES[term.to_s]
    stub_request(:get, "#{MarketData::BanxicoGateway::BASE_URL}series/#{series_id}/datos/oportuno")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          bmx: { series: [ { "idSerie" => series_id, "datos" => [] } ] }
        }.to_json
      )
  end

  def stub_banxico_rate_limited
    stub_request(:get, %r{banxico\.org\.mx/SieAPIRest/service/v1/series/.*/datos/oportuno})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_banxico_server_error
    stub_request(:get, %r{banxico\.org\.mx/SieAPIRest/service/v1/series/.*/datos/oportuno})
      .to_return(status: 500, body: "Internal Server Error")
  end

  private

  def stub_yahoo_chart(symbol, price:, previous_close:, volume: 0, short_name: nil, regular_start: nil, regular_end: nil)
    now = Time.current.to_i
    meta = {
      "symbol" => symbol,
      "regularMarketPrice" => price,
      "chartPreviousClose" => previous_close,
      "regularMarketVolume" => volume,
      "shortName" => short_name || symbol,
      "longName" => short_name || symbol,
      "currentTradingPeriod" => {
        "regular" => {
          "start" => regular_start || now - 3600,
          "end" => regular_end || now + 3600
        }
      }
    }

    encoded = symbol.gsub("^", "%5E")
    stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/#{Regexp.escape(encoded)}})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          chart: {
            result: [ { "meta" => meta, "timestamp" => [ now ], "indicators" => {} } ],
            error: nil
          }
        }.to_json
      )
  end
end

RSpec.configure do |config|
  config.include WebmockHelpers
end
