module MarketData
  module Gateways
    # Driven adapter: Financial Modeling Prep API for fundamentals, dividends, and splits.
    # Free tier: 250 calls/day. Docs: https://financialmodelingprep.com/developer/docs
    class FmpGateway < MarketDataGateway
    include PerformsRequests
    include ResolvesApiKey
    include MarketData::Domain::SafeDecimal
    include Dry::Monads[:result]

    BASE_URL = "https://financialmodelingprep.com"
    PROVIDER = "FMP"
    TIMEOUT  = 10

    def initialize(api_key: nil)
      @api_key = api_key || resolve_api_key
    end

    # Fetch company overview (profile + key metrics).
    # Returns Success({ symbol:, name:, eps:, market_cap:, ... }) matching AlphaVantageGateway schema.
    def fetch_overview(symbol)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      result = get_json("/api/v3/profile/#{symbol}", { apikey: @api_key })
      return result if result.failure?

      parse_overview(result.value!)
    end

    # Fetch historical dividends for a stock symbol.
    # Returns Success([{ ex_date:, pay_date:, amount_per_share:, currency: }, ...])
    def fetch_dividends(symbol)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      result = get_json("/api/v3/historical-price-full/stock_dividend/#{symbol}", { apikey: @api_key })
      return result if result.failure?

      parse_dividends(result.value!)
    end

    # Fetch historical stock splits for a symbol.
    # Returns Success([{ date:, numerator:, denominator: }, ...])
    def fetch_splits(symbol)
      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      result = get_json("/api/v3/historical-price-full/stock_split/#{symbol}", { apikey: @api_key })
      return result if result.failure?

      parse_splits(result.value!)
    end

    private

    def connection
      build_connection(url: BASE_URL, timeout: TIMEOUT, retry_options: { max: 2, interval: 0.5, backoff_factor: 2, retry_statuses: [ 500, 502, 503 ] })
    end

    def parse_overview(body)
      return Failure([ :not_found, "No profile data from FMP" ]) unless body.is_a?(Array) && body.first.present?

      profile = body.first

      # No price key and no lastDiv fallback for eps, deliberately (#554): the
      # price chain owns Asset#current_price, and lastDiv is mapped as itself.
      Success({
        symbol: profile["symbol"],
        name: profile["companyName"],
        description: profile["description"],
        sector: profile["sector"],
        industry: profile["industry"],
        exchange: profile["exchangeShortName"] || profile["exchange"],
        currency: profile["currency"],
        country: profile["country"],
        market_cap: safe_decimal(profile["mktCap"]),
        pe_ratio: safe_decimal(profile["pe"]),
        book_value: nil,
        eps: safe_decimal(profile["eps"]),
        dividend_per_share: safe_decimal(profile["lastDiv"]),
        dividend_yield: nil,
        profit_margin: nil,
        operating_margin: nil,
        return_on_equity: nil,
        return_on_assets: nil,
        revenue_ttm: nil,
        gross_profit_ttm: nil,
        ebitda: nil,
        revenue_per_share: nil,
        beta: safe_decimal(profile["beta"]),
        shares_outstanding: nil,
        ev_to_revenue: nil,
        ev_to_ebitda: nil,
        price_to_sales: nil,
        price_to_book: nil,
        fifty_two_week_high: safe_decimal(profile["range"]&.split("-")&.last),
        fifty_two_week_low: safe_decimal(profile["range"]&.split("-")&.first),
        analyst_target_price: safe_decimal(profile["dcf"]),
        quarterly_earnings_growth: nil,
        quarterly_revenue_growth: nil,
        forward_pe: nil,
        peg_ratio: nil
      })
    end

    def parse_dividends(body)
      historical = body["historical"]
      return Success([]) unless historical.is_a?(Array)

      dividends = historical.filter_map do |entry|
        next unless entry["date"].present? && entry["dividend"].present?

        {
          ex_date: Date.parse(entry["date"]),
          pay_date: entry["paymentDate"].present? ? Date.parse(entry["paymentDate"]) : nil,
          amount_per_share: entry["dividend"].to_d,
          currency: "USD"
        }
      rescue Date::Error
        next
      end

      Success(dividends)
    end

    def parse_splits(body)
      historical = body["historical"]
      return Success([]) unless historical.is_a?(Array)

      splits = historical.filter_map do |entry|
        next unless entry["date"].present? && entry["numerator"].present? && entry["denominator"].present?

        {
          date: Date.parse(entry["date"]),
          numerator: entry["numerator"].to_i,
          denominator: entry["denominator"].to_i
        }
      rescue Date::Error
        next
      end

      Success(splits)
    end
    end
  end
end
