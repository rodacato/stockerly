module MarketData
  module Gateways
    # Driven adapter: CoinGecko REST API for cryptocurrency prices and market data.
    # Docs: https://docs.coingecko.com/reference/simple-price
    # Docs: https://docs.coingecko.com/reference/coins-markets
    class CoingeckoGateway < MarketDataGateway
    include Dry::Monads[:result]

    DEMO_URL = "https://api.coingecko.com"
    PRO_URL  = "https://pro-api.coingecko.com"
    PROVIDER = "CoinGecko"
    TIMEOUT  = 5

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
    # Returns Success({ symbol:, price:, change_percent:, market_cap: })
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
    def fetch_historical(symbol, days: 30)
      coin_id = SYMBOL_TO_ID[symbol.upcase]
      return Failure([ :not_found, "Unknown crypto symbol: #{symbol}" ]) unless coin_id

      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("/api/v3/coins/#{coin_id}/market_chart") do |req|
        req.params["vs_currency"] = "usd"
        req.params["days"] = days.to_s
        req.params["interval"] = "daily"
        apply_auth(req)
      end

      return Failure([ :rate_limited, "CoinGecko rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "CoinGecko returned #{response.status}" ]) unless response.success?

      parse_historical(response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Fetch prices for multiple crypto symbols in a single API call.
    # Returns Success([{ symbol:, price:, ... }, ...])
    def fetch_bulk_prices(symbols)
      ids = symbols.filter_map { |s| SYMBOL_TO_ID[s.upcase] }
      return Success([]) if ids.empty?

      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("/api/v3/simple/price") do |req|
        req.params["ids"] = ids.join(",")
        req.params["vs_currencies"] = "usd"
        req.params["include_24hr_change"] = "true"
        req.params["include_market_cap"] = "true"
        apply_auth(req)
      end

      return Failure([ :rate_limited, "CoinGecko rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "CoinGecko returned #{response.status}" ]) unless response.success?

      parse_bulk(symbols, response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    # Fetch extended market data via /coins/markets endpoint.
    # Returns richer data including supply, FDV, ATH/ATL, and volume.
    def fetch_market_data(symbols)
      ids = symbols.filter_map { |s| SYMBOL_TO_ID[s.upcase] }
      return Success([]) if ids.empty?

      check = RateLimiter.check!(PROVIDER)
      return check if check.failure?

      response = connection.get("/api/v3/coins/markets") do |req|
        req.params["vs_currency"] = "usd"
        req.params["ids"] = ids.join(",")
        req.params["order"] = "market_cap_desc"
        req.params["sparkline"] = "false"
        apply_auth(req)
      end

      return Failure([ :rate_limited, "CoinGecko rate limit exceeded" ]) if response.status == 429
      return Failure([ :gateway_error, "CoinGecko returned #{response.status}" ]) unless response.success?

      parse_market_data(symbols, response.body)
    rescue Faraday::Error => e
      Failure([ :gateway_error, e.message ])
    end

    private

    def connection
      base = @pro ? PRO_URL : DEMO_URL
      @connection ||= Faraday.new(url: base) do |f|
        f.request :retry, max: 2, interval: 1, backoff_factor: 2,
                          retry_statuses: [ 500, 502, 503 ]
        f.response :json
        f.options.timeout = TIMEOUT
        f.options.open_timeout = TIMEOUT
      end
    end

    def apply_auth(req)
      return unless @api_key.present?

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
          price: data["usd"].to_d,
          change_percent: data["usd_24h_change"]&.to_d&.round(4) || 0,
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
          date: Time.at(timestamp_ms / 1000).to_date,
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

    def resolve_api_key
      Integration.find_by(provider_name: "CoinGecko")&.api_key_encrypted ||
        ENV.fetch("COINGECKO_API_KEY", "")
    rescue ActiveRecord::Encryption::Errors::Decryption
      ENV.fetch("COINGECKO_API_KEY", "")
    end

    def resolve_pro_tier
      ENV.fetch("COINGECKO_PRO", "false") == "true"
    end
    end
  end
end
