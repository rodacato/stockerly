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
      result = get_json("/api/v3/profile/#{symbol}", { apikey: @api_key })
      return result if result.failure?

      parse_overview(result.value!)
    end

    # Fetch historical dividends for a stock symbol.
    # Returns Success([{ ex_date:, pay_date:, amount_per_share:, currency: }, ...])
    def fetch_dividends(symbol)
      result = get_json("/api/v3/historical-price-full/stock_dividend/#{symbol}", { apikey: @api_key })
      return result if result.failure?

      parse_dividends(result.value!)
    end

    # Fetch historical stock splits for a symbol.
    # Returns Success([{ date:, numerator:, denominator: }, ...])
    def fetch_splits(symbol)
      result = get_json("/api/v3/historical-price-full/stock_split/#{symbol}", { apikey: @api_key })
      return result if result.failure?

      parse_splits(result.value!)
    end

    private

    def connection
      build_connection(url: BASE_URL, timeout: TIMEOUT, retry_options: { max: 2, interval: 0.5, backoff_factor: 2, retry_statuses: [ 500, 502, 503 ] })
    end

    def parse_overview(body)
      profile = body.first if body.is_a?(Array)
      return Failure([ :not_found, "No profile data from FMP" ]) if profile.blank?

      low, high = profile["range"].to_s.split("-")

      # No price key and no lastDiv fallback for eps, deliberately (#554): the
      # price chain owns Asset#current_price, and lastDiv is mapped as itself.
      #
      # Only what /profile answers. The nineteen keys FMP does not serve used to
      # be spelled out as nil to match Alpha Vantage's shape; the row is jsonb
      # and every reader goes through present?, so an absent key and a null one
      # are the same value read twice (#559).
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
        eps: safe_decimal(profile["eps"]),
        dividend_per_share: safe_decimal(profile["lastDiv"]),
        beta: safe_decimal(profile["beta"]),
        fifty_two_week_high: safe_decimal(high),
        fifty_two_week_low: safe_decimal(low),
        analyst_target_price: safe_decimal(profile["dcf"])
      })
    end

    def parse_dividends(body)
      historical = body["historical"]
      return Success([]) unless historical.is_a?(Array)

      dividends = historical.filter_map do |entry|
        ex_date, amount, pay_date = entry.values_at("date", "dividend", "paymentDate")
        next unless ex_date.present? && amount.present?

        {
          ex_date: Date.parse(ex_date),
          pay_date: pay_date.present? ? Date.parse(pay_date) : nil,
          amount_per_share: amount.to_d,
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
        date, numerator, denominator = entry.values_at("date", "numerator", "denominator")
        next if [ date, numerator, denominator ].any?(&:blank?)

        {
          date: Date.parse(date),
          numerator: numerator.to_i,
          denominator: denominator.to_i
        }
      rescue Date::Error
        next
      end

      Success(splits)
    end
    end
  end
end
