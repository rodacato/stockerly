module Administration
  module Domain
    class AssetCatalog
      CATALOG = {
        us_stocks: [
          { symbol: "AAPL", name: "Apple Inc.", asset_type: "stock", exchange: "NASDAQ", sector: "Technology", country: "US", data_source: "Polygon.io" },
          { symbol: "MSFT", name: "Microsoft Corp.", asset_type: "stock", exchange: "NASDAQ", sector: "Technology", country: "US", data_source: "Polygon.io" },
          { symbol: "GOOGL", name: "Alphabet Inc.", asset_type: "stock", exchange: "NASDAQ", sector: "Technology", country: "US", data_source: "Polygon.io" },
          { symbol: "AMZN", name: "Amazon.com Inc.", asset_type: "stock", exchange: "NASDAQ", sector: "Consumer Cyclical", country: "US", data_source: "Polygon.io" },
          { symbol: "NVDA", name: "NVIDIA Corp.", asset_type: "stock", exchange: "NASDAQ", sector: "Technology", country: "US", data_source: "Polygon.io" },
          { symbol: "META", name: "Meta Platforms", asset_type: "stock", exchange: "NASDAQ", sector: "Technology", country: "US", data_source: "Polygon.io" },
          { symbol: "TSLA", name: "Tesla, Inc.", asset_type: "stock", exchange: "NASDAQ", sector: "Consumer Cyclical", country: "US", data_source: "Polygon.io" },
          { symbol: "JPM", name: "JPMorgan Chase", asset_type: "stock", exchange: "NYSE", sector: "Finance", country: "US", data_source: "Polygon.io" },
          { symbol: "JNJ", name: "Johnson & Johnson", asset_type: "stock", exchange: "NYSE", sector: "Healthcare", country: "US", data_source: "Polygon.io" },
          { symbol: "KO", name: "Coca-Cola Co.", asset_type: "stock", exchange: "NYSE", sector: "Consumer", country: "US", data_source: "Polygon.io" },
          { symbol: "PG", name: "Procter & Gamble", asset_type: "stock", exchange: "NYSE", sector: "Consumer", country: "US", data_source: "Polygon.io" },
          { symbol: "OKE", name: "Oneok Inc.", asset_type: "stock", exchange: "NYSE", sector: "Energy", country: "US", data_source: "Polygon.io" }
        ],
        crypto: [
          { symbol: "BTC", name: "Bitcoin", asset_type: "crypto", data_source: "CoinGecko API" },
          { symbol: "ETH", name: "Ethereum", asset_type: "crypto", data_source: "CoinGecko API" },
          { symbol: "SOL", name: "Solana", asset_type: "crypto", data_source: "CoinGecko API" },
          { symbol: "ADA", name: "Cardano", asset_type: "crypto", data_source: "CoinGecko API" },
          { symbol: "DOT", name: "Polkadot", asset_type: "crypto", data_source: "CoinGecko API" },
          { symbol: "DOGE", name: "Dogecoin", asset_type: "crypto", data_source: "CoinGecko API" }
        ],
        etfs: [
          { symbol: "SPY", name: "SPDR S&P 500 ETF", asset_type: "etf", exchange: "NYSE", country: "US", data_source: "Polygon.io" },
          { symbol: "QQQ", name: "Invesco QQQ Trust", asset_type: "etf", exchange: "NASDAQ", country: "US", data_source: "Polygon.io" },
          { symbol: "VOO", name: "Vanguard S&P 500", asset_type: "etf", exchange: "NYSE", country: "US", data_source: "Polygon.io" },
          { symbol: "VTI", name: "Vanguard Total Stock", asset_type: "etf", exchange: "NYSE", country: "US", data_source: "Polygon.io" },
          { symbol: "ARKK", name: "ARK Innovation ETF", asset_type: "etf", exchange: "NYSE", country: "US", data_source: "Polygon.io" }
        ],
        mexican_stocks: [
          { symbol: "GENIUSSACV.MX", name: "Genius Sports SAB", asset_type: "stock", exchange: "BMV", sector: "Technology", country: "MX", data_source: "Yahoo Finance" },
          { symbol: "IVVPESO.MX", name: "iShares S&P 500 MXN", asset_type: "etf", exchange: "BMV", country: "MX", data_source: "Yahoo Finance" }
        ],
        fixed_income: [
          { symbol: "CETE28D", name: "CETES 28 Dias", asset_type: "fixed_income", exchange: "Banxico", country: "MX" },
          { symbol: "CETE91D", name: "CETES 91 Dias", asset_type: "fixed_income", exchange: "Banxico", country: "MX" },
          { symbol: "CETE182D", name: "CETES 182 Dias", asset_type: "fixed_income", exchange: "Banxico", country: "MX" },
          { symbol: "CETE364D", name: "CETES 364 Dias", asset_type: "fixed_income", exchange: "Banxico", country: "MX" }
        ]
      }.freeze

      DEFAULT_SELECTED = %w[AAPL MSFT GOOGL NVDA BTC ETH SPY].freeze

      def self.all = CATALOG
      def self.flat = CATALOG.values.flatten
      def self.symbols = flat.map { |a| a[:symbol] }
      def self.categories = CATALOG.keys
      def self.find_by_symbols(symbols) = flat.select { |a| symbols.include?(a[:symbol]) }

      def self.category_label(key)
        {
          us_stocks: "US Stocks",
          crypto: "Cryptocurrency",
          etfs: "ETFs",
          mexican_stocks: "Mexican Stocks",
          fixed_income: "Fixed Income (CETES)"
        }[key]
      end
    end
  end
end
