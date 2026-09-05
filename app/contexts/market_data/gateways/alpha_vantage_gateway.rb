module MarketData
  module Gateways
    # Driven adapter: Alpha Vantage REST API for fundamental financial data.
    # Docs: https://www.alphavantage.co/documentation/
    # CRITICAL: Rate limits return HTTP 200 with "Note" key (NOT 429).
    class AlphaVantageGateway < FundamentalsGateway
    include PerformsRequests
    include ResolvesApiKey
    include MarketData::Domain::SafeDecimal
    BASE_URL = "https://www.alphavantage.co"
    PROVIDER = "Alpha Vantage"
    QUERY_PATH = "/query"
    TIMEOUT_MESSAGE = "#{PROVIDER} request timed out"
    TIMEOUT_ERRORS = [ Faraday::TimeoutError, Faraday::ConnectionFailed ].freeze
    TIMEOUT  = 10

    def initialize(api_key: nil)
      @api_key = api_key || resolve_api_key
    end

    # Fetch company overview (50+ metrics in one call).
    # Returns Success({ symbol:, eps:, book_value:, ... })
    def fetch_overview(symbol)
      result = get_json(QUERY_PATH, { function: "OVERVIEW", symbol: symbol, apikey: @api_key })
      return result if result.failure?

      body = result.value!
      return Failure([ :rate_limited, body["Note"] ]) if body.key?("Note")
      return Failure([ :auth_error, body["Information"] ]) if body.key?("Information")
      return Failure([ :not_found, "No data for #{symbol}" ]) if body["Symbol"].blank?

      parse_overview(body)
    end

    # Fetch income statement (annual + quarterly reports).
    # Returns Success({ symbol:, annual_reports: [...], quarterly_reports: [...] })
    def fetch_income_statement(symbol)
      fetch_statement(symbol, "INCOME_STATEMENT")
    end

    # Fetch balance sheet (annual + quarterly reports).
    def fetch_balance_sheet(symbol)
      fetch_statement(symbol, "BALANCE_SHEET")
    end

    # Fetch cash flow statement (annual + quarterly reports).
    def fetch_cash_flow(symbol)
      fetch_statement(symbol, "CASH_FLOW")
    end

    # Search tickers by keyword via SYMBOL_SEARCH endpoint.
    # Returns Success([{ symbol:, name:, quote_type:, exchange:, exchange_display: }, ...])
    def search_tickers(query)
      result = get_json(QUERY_PATH, { function: "SYMBOL_SEARCH", keywords: query, apikey: @api_key })
      return result if result.failure?

      body = result.value!
      return Failure([ :rate_limited, body["Note"] ]) if body.key?("Note")
      return Failure([ :auth_error, body["Information"] ]) if body.key?("Information")

      matches = body["bestMatches"] || []
      Success(matches.filter_map { |m| parse_search_match(m) })
    end

    private

    # Maps Alpha Vantage SYMBOL_SEARCH result to normalized format.
    def parse_search_match(match)
      symbol = match["1. symbol"]
      return nil if symbol.blank?

      av_type = match["3. type"]
      quote_type = case av_type
      when "Equity" then "EQUITY"
      when "ETF" then "ETF"
      when "Mutual Fund" then "MUTUALFUND"
      else "EQUITY"
      end

      {
        symbol: symbol,
        name: match["2. name"] || symbol,
        quote_type: quote_type,
        exchange: match["4. region"] || "",
        exchange_display: match["4. region"] || "",
        currency: match["8. currency"]
      }
    end

    # Shared fetch + parse logic for all 3 statement types.
    def fetch_statement(symbol, function)
      result = get_json(QUERY_PATH, { function: function, symbol: symbol, apikey: @api_key })
      return result if result.failure?

      body = result.value!
      return Failure([ :rate_limited, body["Note"] ]) if body.key?("Note")
      return Failure([ :auth_error, body["Information"] ]) if body.key?("Information")
      return Failure([ :empty_data, "No data for #{symbol}" ]) if body["annualReports"].blank? && body["quarterlyReports"].blank?

      Success({
        symbol: body["symbol"] || symbol,
        annual_reports: (body["annualReports"] || []).map { |r| normalize_keys(r) },
        quarterly_reports: (body["quarterlyReports"] || []).map { |r| normalize_keys(r) }
      })
    end

    # Converts Alpha Vantage PascalCase keys to snake_case for consistency.
    def normalize_keys(report)
      report.transform_keys { |k| k.underscore }
    end

    # The only provider whose transport failures are named rather than collapsed
    # into :gateway_error.
    def transport_failure(error)
      return Failure([ :timeout, TIMEOUT_MESSAGE ]) if TIMEOUT_ERRORS.any? { |klass| error.is_a?(klass) }

      super
    end

    # One retry, not two: the free tier allows five calls a minute, so a second
    # attempt spends the budget the next caller needs.
    def connection
      build_connection(url: BASE_URL, timeout: TIMEOUT,
                       retry_options: { max: 1, interval: 1.0, retry_statuses: [ 500, 502, 503 ] })
    end

    def parse_overview(body)
      Success({
        symbol: body["Symbol"],
        name: body["Name"],
        description: body["Description"],
        sector: body["Sector"],
        industry: body["Industry"],
        exchange: body["Exchange"],
        currency: body["Currency"],
        country: body["Country"],
        market_cap: safe_decimal(body["MarketCapitalization"]),
        pe_ratio: safe_decimal(body["PERatio"]),
        forward_pe: safe_decimal(body["ForwardPE"]),
        peg_ratio: safe_decimal(body["PEGRatio"]),
        book_value: safe_decimal(body["BookValue"]),
        eps: safe_decimal(body["EPS"]),
        dividend_per_share: safe_decimal(body["DividendPerShare"]),
        dividend_yield: safe_decimal(body["DividendYield"]),
        profit_margin: safe_decimal(body["ProfitMargin"]),
        operating_margin: safe_decimal(body["OperatingMarginTTM"]),
        return_on_equity: safe_decimal(body["ReturnOnEquityTTM"]),
        return_on_assets: safe_decimal(body["ReturnOnAssetsTTM"]),
        revenue_ttm: safe_decimal(body["RevenueTTM"]),
        gross_profit_ttm: safe_decimal(body["GrossProfitTTM"]),
        ebitda: safe_decimal(body["EBITDA"]),
        revenue_per_share: safe_decimal(body["RevenuePerShareTTM"]),
        beta: safe_decimal(body["Beta"]),
        shares_outstanding: safe_decimal(body["SharesOutstanding"]),
        ev_to_revenue: safe_decimal(body["EVToRevenue"]),
        ev_to_ebitda: safe_decimal(body["EVToEBITDA"]),
        price_to_sales: safe_decimal(body["PriceToSalesRatioTTM"]),
        price_to_book: safe_decimal(body["PriceToBookRatio"]),
        fifty_two_week_high: safe_decimal(body["52WeekHigh"]),
        fifty_two_week_low: safe_decimal(body["52WeekLow"]),
        analyst_target_price: safe_decimal(body["AnalystTargetPrice"]),
        quarterly_earnings_growth: safe_decimal(body["QuarterlyEarningsGrowthYOY"]),
        quarterly_revenue_growth: safe_decimal(body["QuarterlyRevenueGrowthYOY"])
      })
    end
    end
  end
end
