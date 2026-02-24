# Registers all known data sources at boot time.
# New sources should be added here so they appear in admin and are
# resolvable by SyncIntegrationJob.

Rails.application.config.after_initialize do
  DataSourceRegistry.register(:polygon_stocks,
    name: "US Stocks — Polygon.io",
    icon: "show_chart",
    color: "indigo",
    gateway_class: PolygonGateway,
    job_class: SyncPriorityAssetsJob,
    job_args: %w[stock high],
    test_symbol: "AAPL",
    integration_name: "Polygon.io",
    circuit_breaker_key: "stock"
  )

  DataSourceRegistry.register(:coingecko_crypto,
    name: "Crypto — CoinGecko",
    icon: "currency_bitcoin",
    color: "emerald",
    gateway_class: CoingeckoGateway,
    job_class: SyncPriorityAssetsJob,
    job_args: %w[crypto high],
    test_symbol: "BTC",
    integration_name: "CoinGecko",
    circuit_breaker_key: "crypto"
  )

  DataSourceRegistry.register(:yahoo_bmv,
    name: "Mexican Stocks — Yahoo Finance",
    icon: "language",
    color: "sky",
    gateway_class: YahooFinanceGateway,
    job_class: SyncPriorityAssetsJob,
    job_args: %w[stock high],
    test_symbol: "GENIUSSACV.MX",
    integration_name: "Yahoo Finance",
    circuit_breaker_key: "bmv"
  )

  DataSourceRegistry.register(:crypto_fear_greed,
    name: "Crypto F&G — Alternative.me",
    icon: "psychology",
    color: "purple",
    gateway_class: CryptoFearGreedGateway,
    job_class: RefreshFearGreedJob,
    job_args: [],
    test_symbol: nil,
    integration_name: "Alternative.me",
    circuit_breaker_key: "crypto_fear_greed"
  )

  DataSourceRegistry.register(:stock_fear_greed,
    name: "Stock F&G — CNN",
    icon: "psychology",
    color: "rose",
    gateway_class: StockFearGreedGateway,
    job_class: RefreshFearGreedJob,
    job_args: [],
    test_symbol: nil,
    integration_name: "CNN",
    circuit_breaker_key: "stock_fear_greed"
  )

  DataSourceRegistry.register(:polygon_news,
    name: "News — Polygon.io",
    icon: "newspaper",
    color: "slate",
    gateway_class: PolygonGateway,
    job_class: SyncNewsJob,
    job_args: [],
    test_symbol: nil,
    integration_name: "Polygon.io",
    circuit_breaker_key: "polygon_news"
  )

  DataSourceRegistry.register(:yahoo_indices,
    name: "Market Indices — Yahoo Finance",
    icon: "monitoring",
    color: "teal",
    gateway_class: YahooFinanceGateway,
    job_class: SyncMarketIndicesJob,
    job_args: [],
    test_symbol: nil,
    integration_name: "Yahoo Finance",
    circuit_breaker_key: "yahoo_indices"
  )

  DataSourceRegistry.register(:alpha_vantage_fundamentals,
    name: "Fundamentals — Alpha Vantage",
    icon: "analytics",
    color: "orange",
    gateway_class: AlphaVantageGateway,
    job_class: SyncAllFundamentalsJob,
    job_args: [],
    test_symbol: "AAPL",
    integration_name: "Alpha Vantage",
    circuit_breaker_key: "alpha_vantage"
  )

  DataSourceRegistry.register(:polygon_earnings,
    name: "Earnings — Polygon.io",
    icon: "event_note",
    color: "violet",
    gateway_class: PolygonGateway,
    job_class: SyncEarningsJob,
    job_args: [],
    test_symbol: "AAPL",
    integration_name: "Polygon.io",
    circuit_breaker_key: "polygon_earnings"
  )

  DataSourceRegistry.register(:fx_rates,
    name: "FX Rates",
    icon: "currency_exchange",
    color: "amber",
    gateway_class: FxRatesGateway,
    job_class: RefreshFxRatesJob,
    job_args: [],
    test_symbol: nil,
    integration_name: nil,
    circuit_breaker_key: "fx"
  )
end
