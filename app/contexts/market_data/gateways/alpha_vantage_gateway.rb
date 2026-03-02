module MarketData
  # Driven adapter: Alpha Vantage REST API for fundamental financial data.
  # Docs: https://www.alphavantage.co/documentation/
  # CRITICAL: Rate limits return HTTP 200 with "Note" key (NOT 429).
  class AlphaVantageGateway < FundamentalsGateway
    BASE_URL = "https://www.alphavantage.co"
    PROVIDER = "Alpha Vantage"
    TIMEOUT  = 10

    def initialize(api_key: nil)
      @api_key = api_key || resolve_api_key
    end

    # Fetch company overview (50+ metrics in one call).
    # Returns Success({ symbol:, eps:, book_value:, ... })
    def fetch_overview(symbol)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("/query") do |req|
        req.params["function"] = "OVERVIEW"
        req.params["symbol"] = symbol
        req.params["apikey"] = @api_key
      end

      return Failure([ :gateway_error, "Alpha Vantage returned #{response.status}" ]) unless response.success?

      body = response.body
      return Failure([ :rate_limited, body["Note"] ]) if body.key?("Note")
      return Failure([ :auth_error, body["Information"] ]) if body.key?("Information")
      return Failure([ :not_found, "No data for #{symbol}" ]) if body["Symbol"].blank?

      parse_overview(body)
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed
      Failure([ :timeout, "Alpha Vantage request timed out" ])
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    rescue JSON::ParserError
      Failure([ :parse_error, "Invalid JSON response from Alpha Vantage" ])
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

    private

    # Shared fetch + parse logic for all 3 statement types.
    def fetch_statement(symbol, function)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("/query") do |req|
        req.params["function"] = function
        req.params["symbol"] = symbol
        req.params["apikey"] = @api_key
      end

      return Failure([ :gateway_error, "Alpha Vantage returned #{response.status}" ]) unless response.success?

      body = response.body
      return Failure([ :rate_limited, body["Note"] ]) if body.key?("Note")
      return Failure([ :auth_error, body["Information"] ]) if body.key?("Information")
      return Failure([ :empty_data, "No data for #{symbol}" ]) if body["annualReports"].blank? && body["quarterlyReports"].blank?

      Success({
        symbol: body["symbol"] || symbol,
        annual_reports: (body["annualReports"] || []).map { |r| normalize_keys(r) },
        quarterly_reports: (body["quarterlyReports"] || []).map { |r| normalize_keys(r) }
      })
    rescue Faraday::TimeoutError, Faraday::ConnectionFailed
      Failure([ :timeout, "Alpha Vantage request timed out" ])
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    rescue JSON::ParserError
      Failure([ :parse_error, "Invalid JSON response from Alpha Vantage" ])
    end

    # Converts Alpha Vantage PascalCase keys to snake_case for consistency.
    def normalize_keys(report)
      report.transform_keys { |k| k.underscore }
    end

    def connection
      @connection ||= Faraday.new(url: BASE_URL) do |f|
        f.request :retry, max: 1, interval: 1.0, retry_statuses: [ 500, 502, 503 ]
        f.response :json
        f.options.timeout = TIMEOUT
        f.options.open_timeout = TIMEOUT
      end
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

    # Alpha Vantage returns "None" for missing values
    def safe_decimal(value)
      return nil if value.blank? || value == "None" || value == "-"
      BigDecimal(value.to_s)
    rescue ArgumentError
      nil
    end

    def resolve_api_key
      Integration.find_by(provider_name: "Alpha Vantage")&.api_key_encrypted ||
        ENV.fetch("ALPHA_VANTAGE_API_KEY", "")
    rescue ActiveRecord::Encryption::Errors::Decryption
      ENV.fetch("ALPHA_VANTAGE_API_KEY", "")
    end
  end
end
