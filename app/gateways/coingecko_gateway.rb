# Driven adapter: CoinGecko REST API for cryptocurrency prices.
# Docs: https://docs.coingecko.com/reference/simple-price
class CoingeckoGateway < MarketDataGateway
  include Dry::Monads[:result]

  BASE_URL = "https://api.coingecko.com"
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

  def initialize(api_key: nil)
    @api_key = api_key || resolve_api_key
  end

  # Fetch price for a single crypto symbol.
  # Returns Success({ symbol:, price:, change_percent:, market_cap: })
  def fetch_price(symbol)
    coin_id = SYMBOL_TO_ID[symbol.upcase]
    return Failure([:not_found, "Unknown crypto symbol: #{symbol}"]) unless coin_id

    fetch_bulk_prices([symbol]).bind do |results|
      result = results.first
      result ? Success(result) : Failure([:not_found, "No data for #{symbol}"])
    end
  end

  # Fetch prices for multiple crypto symbols in a single API call.
  # Returns Success([{ symbol:, price:, ... }, ...])
  def fetch_bulk_prices(symbols)
    ids = symbols.filter_map { |s| SYMBOL_TO_ID[s.upcase] }
    return Success([]) if ids.empty?

    response = connection.get("/api/v3/simple/price") do |req|
      req.params["ids"] = ids.join(",")
      req.params["vs_currencies"] = "usd"
      req.params["include_24hr_change"] = "true"
      req.params["include_market_cap"] = "true"
      req.headers["x-cg-demo-api-key"] = @api_key if @api_key.present?
    end

    return Failure([:rate_limited, "CoinGecko rate limit exceeded"]) if response.status == 429
    return Failure([:gateway_error, "CoinGecko returned #{response.status}"]) unless response.success?

    parse_bulk(symbols, response.body)
  rescue Faraday::Error => e
    Failure([:gateway_error, e.message])
  end

  private

  def connection
    @connection ||= Faraday.new(url: BASE_URL) do |f|
      f.request :retry, max: 2, interval: 1, backoff_factor: 2,
                        retry_statuses: [500, 502, 503]
      f.response :json
      f.options.timeout = TIMEOUT
      f.options.open_timeout = TIMEOUT
    end
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

  def resolve_api_key
    Integration.find_by(provider_name: "CoinGecko")&.api_key_encrypted ||
      ENV.fetch("COINGECKO_API_KEY", "")
  end
end
