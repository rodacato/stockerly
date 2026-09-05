module MarketData
  module Gateways
    # Driven adapter: CoinGecko REST API for cryptocurrency prices and market data.
    # Docs: https://docs.coingecko.com/reference/simple-price
    # Docs: https://docs.coingecko.com/reference/coins-markets
    class CoingeckoGateway < MarketDataGateway
    include PerformsRequests
    include ResolvesApiKey
    include Dry::Monads[:result]

    DEMO_URL = "https://api.coingecko.com"
    PRO_URL  = "https://pro-api.coingecko.com"
    PROVIDER = "CoinGecko"

    # Crypto is quoted against USD everywhere, and CoinGecko's MXN is that
    # number times an FX rate it does not publish — measured 2026-08-26, the
    # implied rate was identical across coins (16.9454) and 0.11% off Banxico's
    # FIX. Converting here would hide the hop, not remove it, and would trade an
    # auditable settlement reference for an undisclosed one.
    QUOTE_CURRENCY = "usd".freeze
    TIMEOUT  = 5

    # Probed 2026-09-04: days=3650 answers 401 error_code 10012, "Public API
    # users are limited to querying historical data within the past 365 days".
    # A refusal, not a truncation, so asking for more returns nothing at all.
    MAX_HISTORY_DAYS = 365

    def self.max_history_days = MAX_HISTORY_DAYS

    # CoinGecko uses lowercase IDs, not ticker symbols.
    SYMBOL_TO_ID = {
      "BTC" => "bitcoin",
      "ETH" => "ethereum",
      "SOL" => "solana",
      "ADA" => "cardano",
      "DOT" => "polkadot",
      "DOGE" => "dogecoin",
      "AVAX" => "avalanche-2",
      "MATIC" => "matic-network",
      "LINK" => "chainlink",
      "UNI" => "uniswap"
    }.freeze

    def initialize(api_key: nil, pro: nil)
      @api_key = api_key || resolve_api_key
      @pro = pro.nil? ? resolve_pro_tier : pro
    end

    # Fetch price for a single crypto symbol.
    # Returns Success({ symbol:, price:, market_cap: })
    def fetch_price(symbol)
      coin_id = SYMBOL_TO_ID[symbol.upcase]
      return Failure([ :not_found, "Unknown crypto symbol: #{symbol}" ]) unless coin_id

      fetch_bulk_prices([ symbol ]).bind do |results|
        result = results.first
        result ? Success(result) : Failure([ :not_found, "No data for #{symbol}" ])
      end
    end

    # Fetch daily price history for a crypto symbol.
    # Returns Success([{ date:, open:, high:, low:, close:, volume: }, ...])
    # CoinGecko counts back from today, so to_date only sets the window length.
    def fetch_historical(symbol, from_date = 30.days.ago.to_date, to_date = Date.current)
      days = (to_date.to_date - from_date.to_date).to_i
      coin_id = SYMBOL_TO_ID[symbol.upcase]
      return Failure([ :not_found, "Unknown crypto symbol: #{symbol}" ]) unless coin_id

      result = get_json("/api/v3/coins/#{coin_id}/market_chart", {
        vs_currency: QUOTE_CURRENCY, days: days.to_s, interval: "daily"
      }) { |req| apply_auth(req) }
      return result if result.failure?

      parse_historical(result.value!)
    end

    # Fetch prices for multiple crypto symbols in a single API call.
    # Returns Success([{ symbol:, price:, ... }, ...])
    def fetch_bulk_prices(symbols)
      ids = symbols.filter_map { |s| SYMBOL_TO_ID[s.upcase] }
      return Success([]) if ids.empty?

      result = get_json("/api/v3/simple/price", {
        ids: ids.join(","), vs_currencies: QUOTE_CURRENCY,
        include_24hr_change: "true", include_market_cap: "true"
      }) { |req| apply_auth(req) }
      return result if result.failure?

      parse_bulk(symbols, result.value!)
    end

    # Fetch extended market data via /coins/markets endpoint.
    # Returns richer data including supply, FDV, ATH/ATL, and volume.
    def fetch_market_data(symbols)
      ids = symbols.filter_map { |s| SYMBOL_TO_ID[s.upcase] }
      return Success([]) if ids.empty?

      result = get_json("/api/v3/coins/markets", {
        vs_currency: QUOTE_CURRENCY, ids: ids.join(","),
        order: "market_cap_desc", sparkline: "false"
      }) { |req| apply_auth(req) }
      return result if result.failure?

      parse_market_data(symbols, result.value!)
    end

    private

    def connection
      build_connection(url: @pro ? PRO_URL : DEMO_URL, timeout: TIMEOUT,
                       retry_options: { max: 2, interval: 1, backoff_factor: 2, retry_statuses: [ 500, 502, 503 ] })
    end

    def apply_auth(req)
      return if @api_key.blank?

      header = @pro ? "x-cg-pro-api-key" : "x-cg-demo-api-key"
      req.headers[header] = @api_key
    end

    def parse_bulk(symbols, body)
      results = symbols.filter_map do |symbol|
        coin_id = SYMBOL_TO_ID[symbol.upcase]
        data = body[coin_id]
        next unless data

        {
          symbol: symbol.upcase,
          price: data[QUOTE_CURRENCY].to_d,
          market_cap: data["usd_market_cap"]&.to_d
        }
      end

      Success(results)
    end

    def parse_historical(body)
      prices = body["prices"]
      return Failure([ :parse_error, "No price data in CoinGecko response" ]) if prices.blank?

      bars = prices.map do |timestamp_ms, price|
        {
          date: Time.at(timestamp_ms / 1000).utc.to_date,
          open: price.to_d,
          high: price.to_d,
          low: price.to_d,
          close: price.to_d,
          volume: nil
        }
      end

      # CoinGecko market_chart returns one extra data point; deduplicate by date
      bars.uniq! { |b| b[:date] }

      Success(bars)
    end

    def parse_market_data(symbols, body)
      return Success([]) unless body.is_a?(Array)

      id_to_symbol = SYMBOL_TO_ID.invert
      results = body.filter_map do |coin|
        symbol = id_to_symbol[coin["id"]]&.upcase
        next unless symbol && symbols.map(&:upcase).include?(symbol)

        {
          symbol: symbol,
          price: coin["current_price"]&.to_d,
          change_percent: coin["price_change_percentage_24h"]&.to_d&.round(4) || 0,
          market_cap: coin["market_cap"]&.to_d,
          circulating_supply: coin["circulating_supply"]&.to_d,
          total_supply: coin["total_supply"]&.to_d,
          max_supply: coin["max_supply"]&.to_d,
          fully_diluted_valuation: coin["fully_diluted_valuation"]&.to_d,
          total_volume: coin["total_volume"]&.to_d,
          ath: coin["ath"]&.to_d,
          ath_change_percentage: coin["ath_change_percentage"]&.to_d,
          atl: coin["atl"]&.to_d,
          atl_change_percentage: coin["atl_change_percentage"]&.to_d
        }
      end

      Success(results)
    end

    def resolve_pro_tier
      integration = Integration.find_by(provider_name: PROVIDER)
      integration&.setting("pro_tier") == true
    end
    end
  end
end
