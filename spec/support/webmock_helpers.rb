# Shared WebMock stubs for external API gateways.
module WebmockHelpers
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
    prices = Array.new(days) do |i|
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

  # Stubs Yahoo's quoteSummary calendarEvents endpoint (used by BMV earnings sync).
  # Pass `dates:` as an Array of Date/Integer (unix). 1 entry = confirmed,
  # 2 entries = unconfirmed range.
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

  def stub_alpha_vantage_ticker_search(keywords, results: [])
    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: hash_including("function" => "SYMBOL_SEARCH", "keywords" => keywords))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { "bestMatches" => results }.to_json
      )
  end

  def stub_alpha_vantage_ticker_search_error(status: 500)
    stub_request(:get, "https://www.alphavantage.co/query")
      .with(query: hash_including("function" => "SYMBOL_SEARCH"))
      .to_return(status: status, body: "Error")
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

  # The whole curve in one request. Banxico answers in its own order, so the
  # blocks are deliberately shuffled here: a positional parser would pass with
  # them sorted and mislabel every term in production.
  def stub_banxico_curve(rates: { "364" => 7.06, "28" => 6.13, "91" => 6.60, "182" => 6.72 }, date: "27/08/2026")
    series_map = MarketData::Gateways::BanxicoGateway::CETES_SERIES
    ids = series_map.values.join(",")

    stub_request(:get, "#{MarketData::Gateways::BanxicoGateway::BASE_URL}series/#{ids}/datos/oportuno")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          bmx: {
            series: rates.map do |term, rate|
              { "idSerie" => series_map[term], "titulo" => "Valores gubernamentales",
                "datos" => [ { "fecha" => date, "dato" => rate.to_s } ] }
            end
          }
        }.to_json
      )
  end

  def stub_banxico_auctions(term: "28", yield_rate: 11.15, date: "25/02/2026")
    series_id = MarketData::Gateways::BanxicoGateway::CETES_SERIES[term.to_s]
    stub_request(:get, "#{MarketData::Gateways::BanxicoGateway::BASE_URL}series/#{series_id}/datos/oportuno")
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

  # D28: the ranged form of the auction endpoint. `datos` carries one entry per
  # auction, which parse_auctions already walks.
  def stub_banxico_auction_series(term: "28", from:, to:, auctions: [])
    series_id = MarketData::Gateways::BanxicoGateway::CETES_SERIES[term.to_s]
    path = "series/#{series_id}/datos/#{from.strftime("%Y-%m-%d")}/#{to.strftime("%Y-%m-%d")}"

    stub_request(:get, "#{MarketData::Gateways::BanxicoGateway::BASE_URL}#{path}")
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          bmx: {
            series: [ {
              "idSerie" => series_id,
              "titulo" => "CETES #{term}D",
              "datos" => auctions.map { |a| { "fecha" => a[:fecha], "dato" => a[:dato].to_s } }
            } ]
          }
        }.to_json
      )
  end

  def stub_banxico_not_found(term: "28")
    series_id = MarketData::Gateways::BanxicoGateway::CETES_SERIES[term.to_s]
    stub_request(:get, "#{MarketData::Gateways::BanxicoGateway::BASE_URL}series/#{series_id}/datos/oportuno")
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

  # --- Finnhub ---

  def stub_finnhub_quote(symbol, current: 150.25, change_percent: 1.69, prev_close: 147.75)
    stub_request(:get, "https://finnhub.io/api/v1/quote")
      .with(query: hash_including("symbol" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          c: current, d: current - prev_close, dp: change_percent,
          h: current + 1, l: current - 1, o: current - 0.5,
          pc: prev_close, t: Time.current.to_i
        }.to_json
      )
  end

  def stub_finnhub_quote_not_found(symbol)
    stub_request(:get, "https://finnhub.io/api/v1/quote")
      .with(query: hash_including("symbol" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { c: 0, d: nil, dp: nil, h: 0, l: 0, o: 0, pc: 0, t: 0 }.to_json
      )
  end

  def stub_finnhub_candles(symbol, days: 7)
    timestamps = Array.new(days) { |i| (days - i).days.ago.to_i }
    stub_request(:get, "https://finnhub.io/api/v1/stock/candle")
      .with(query: hash_including("symbol" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: {
          s: "ok",
          c: Array.new(days) { |i| 183.0 + i },
          o: Array.new(days) { |i| 180.0 + i },
          h: Array.new(days) { |i| 185.0 + i },
          l: Array.new(days) { |i| 178.0 + i },
          v: Array.new(days) { |i| 50_000_000 + (i * 1_000_000) },
          t: timestamps
        }.to_json
      )
  end

  def stub_finnhub_candles_empty(symbol)
    stub_request(:get, "https://finnhub.io/api/v1/stock/candle")
      .with(query: hash_including("symbol" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { s: "no_data" }.to_json
      )
  end

  def stub_finnhub_search(query, count: 2)
    results = [
      { "description" => "APPLE INC", "displaySymbol" => "AAPL", "symbol" => "AAPL", "type" => "Common Stock" },
      { "description" => "APPLE HOSPITALITY REIT", "displaySymbol" => "APLE", "symbol" => "APLE", "type" => "Common Stock" }
    ].first(count)

    stub_request(:get, "https://finnhub.io/api/v1/search")
      .with(query: hash_including("q" => query))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { count: results.size, result: results }.to_json
      )
  end

  def stub_finnhub_search_empty(query)
    stub_request(:get, "https://finnhub.io/api/v1/search")
      .with(query: hash_including("q" => query))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { count: 0, result: [] }.to_json
      )
  end

  def stub_finnhub_rate_limited
    stub_request(:get, %r{finnhub\.io/api/v1/quote})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_finnhub_server_error
    stub_request(:get, %r{finnhub\.io/api/v1/quote})
      .to_return(status: 500, body: "Internal Server Error")
  end

  def stub_finnhub_search_rate_limited
    stub_request(:get, %r{finnhub\.io/api/v1/search})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_finnhub_candles_rate_limited
    stub_request(:get, %r{finnhub\.io/api/v1/stock/candle})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_finnhub_news(symbol, count: 3)
    articles = Array.new(count) do |i|
      {
        "category" => "company news",
        "datetime" => 1.day.ago.to_i + (i * 3600),
        "headline" => "Article #{i + 1} about #{symbol}",
        "id" => 100 + i,
        "image" => "https://example.com/image#{i}.jpg",
        "related" => symbol,
        "source" => "Reuters",
        "summary" => "Summary of article #{i + 1}",
        "url" => "https://example.com/article-#{i + 1}"
      }
    end

    stub_request(:get, %r{finnhub\.io/api/v1/company-news})
      .to_return(status: 200, body: articles.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_finnhub_news_empty(_symbol)
    stub_request(:get, %r{finnhub\.io/api/v1/company-news})
      .to_return(status: 200, body: "[]", headers: { "Content-Type" => "application/json" })
  end

  def stub_finnhub_news_rate_limited
    stub_request(:get, %r{finnhub\.io/api/v1/company-news})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  def stub_finnhub_earnings(symbol, count: 2)
    events = Array.new(count) do |i|
      {
        "date" => (Date.current + (i * 90).days).to_s,
        "epsActual" => i.zero? ? 1.52 : nil,
        "epsEstimate" => 1.45 + (i * 0.1),
        "hour" => i.zero? ? "bmo" : "amc",
        "quarter" => (((Date.current.month / 3.0).ceil + i) % 4) + 1,
        "revenueActual" => i.zero? ? 94_836_000_000 : nil,
        "revenueEstimate" => 92_000_000_000,
        "symbol" => symbol,
        "year" => Date.current.year
      }
    end

    stub_request(:get, %r{finnhub\.io/api/v1/calendar/earnings})
      .to_return(status: 200, body: { "earningsCalendar" => events }.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_finnhub_earnings_empty(_symbol)
    stub_request(:get, %r{finnhub\.io/api/v1/calendar/earnings})
      .to_return(status: 200, body: { "earningsCalendar" => [] }.to_json, headers: { "Content-Type" => "application/json" })
  end

  def stub_finnhub_earnings_rate_limited
    stub_request(:get, %r{finnhub\.io/api/v1/calendar/earnings})
      .to_return(status: 429, body: "Rate limit exceeded")
  end

  private

  # --- Yahoo via the yfinance bridge ---

  def stub_yfinance_quote(symbol, price:, change_percent: 0.0, volume: 1_000)
    allow(PythonRunner).to receive(:call).with("yahoo.py", "quote", symbol)
      .and_return(Dry::Monads::Success({ "price" => price, "change_percent" => change_percent, "volume" => volume }))
  end

  def stub_yfinance_history(symbol, days: 7, close: 180.0)
    bars = Array.new(days) do |i|
      { "date" => (days - i).days.ago.to_date.to_s, "open" => close - 1, "high" => close + 1,
        "low" => close - 2, "close" => close + i, "volume" => 1_000 }
    end
    allow(PythonRunner).to receive(:call).with("yahoo.py", "history", symbol, anything)
      .and_return(Dry::Monads::Success(bars))
  end

  def stub_yfinance_earnings(symbol, events)
    allow(PythonRunner).to receive(:call).with("yahoo.py", "earnings", symbol)
      .and_return(Dry::Monads::Success(events))
  end

  def stub_yfinance_earnings_error(symbol, tag: :gateway_error)
    allow(PythonRunner).to receive(:call).with("yahoo.py", "earnings", symbol)
      .and_return(Dry::Monads::Failure([ tag, "#{symbol} unavailable" ]))
  end

  def stub_yfinance_dividends(symbol, entries)
    allow(PythonRunner).to receive(:call).with("yahoo.py", "dividends", symbol)
      .and_return(Dry::Monads::Success(entries))
  end

  def stub_yfinance_splits(symbol, entries)
    allow(PythonRunner).to receive(:call).with("yahoo.py", "splits", symbol)
      .and_return(Dry::Monads::Success(entries))
  end

  def stub_yfinance_search(query, results: [])
    allow(PythonRunner).to receive(:call).with("yahoo.py", "search", query)
      .and_return(Dry::Monads::Success(results))
  end

  def stub_yfinance_search_failure(query, tag: :gateway_error)
    allow(PythonRunner).to receive(:call).with("yahoo.py", "search", query)
      .and_return(Dry::Monads::Failure([ tag, "#{query} unavailable" ]))
  end

  # One search hit, shaped the way lib/python/yahoo.py emits it.
  def yfinance_match(symbol:, name:, quote_type: "EQUITY", exchange: "NASDAQ", sector: nil)
    { "symbol" => symbol, "name" => name, "quote_type" => quote_type,
      "exchange" => exchange, "sector" => sector }
  end

  def stub_yfinance_not_found(symbol)
    allow(PythonRunner).to receive(:call).with("yahoo.py", anything, symbol, *any_args)
      .and_return(Dry::Monads::Failure([ :not_found, "no data for #{symbol}" ]))
  end

  # --- DataBursatil ---

  def stub_databursatil(path, body, status: 200)
    stub_request(:get, "https://api.databursatil.com#{path}")
      .with(query: hash_including("token"))
      .to_return(status: status, headers: { "Content-Type" => "application/json" }, body: body.to_json)
  end

  def databursatil_quote(last:, change: 1.77, volume: 1_222_566, at: "2026-08-26 10:03:00")
    { "u" => last, "c" => change, "v" => volume, "f" => at }
  end

  # --- Alpaca ---

  def stub_alpaca_bars(bars_by_symbol, next_page_token: nil)
    stub_request(:get, "https://data.alpaca.markets/v2/stocks/bars")
      .with(query: hash_including("feed" => "sip"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { bars: bars_by_symbol, next_page_token: next_page_token }.to_json
      )
  end

  def alpaca_bar(date:, close: 100.0, open: 99.0, volume: 1_000_000)
    { "t" => "#{date}T04:00:00Z", "o" => open, "h" => close + 1, "l" => open - 1, "c" => close, "v" => volume, "n" => 500 }
  end

  def stub_alpaca_recent_denied
    stub_request(:get, %r{data\.alpaca\.markets/v2/stocks})
      .to_return(
        status: 403,
        headers: { "Content-Type" => "application/json" },
        body: { message: "subscription does not permit querying recent SIP data" }.to_json
      )
  end

  def stub_alpaca_rate_limited
    stub_request(:get, %r{data\.alpaca\.markets/})
      .to_return(status: 429, headers: { "Content-Type" => "application/json" }, body: {}.to_json)
  end

  def stub_alpaca_dividends(symbol, entries)
    stub_request(:get, "https://data.alpaca.markets/v1/corporate-actions")
      .with(query: hash_including("symbols" => symbol))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { corporate_actions: { cash_dividends: entries } }.to_json
      )
  end

  def stub_alpaca_splits(symbol, forward: [], reverse: [])
    stub_request(:get, "https://data.alpaca.markets/v1/corporate-actions")
      .with(query: hash_including("symbols" => symbol, "types" => "forward_split,reverse_split"))
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { corporate_actions: { forward_splits: forward, reverse_splits: reverse } }.to_json
      )
  end

  def stub_alpaca_news(items)
    stub_request(:get, %r{data\.alpaca\.markets/v1beta1/news})
      .to_return(
        status: 200,
        headers: { "Content-Type" => "application/json" },
        body: { news: items, next_page_token: nil }.to_json
      )
  end
end

RSpec.configure do |config|
  config.include WebmockHelpers
end
