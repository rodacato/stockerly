# Registers all known data sources at boot time.
# New sources should be added here so they appear in admin and are
# resolvable by SyncIntegrationJob.
#
# Registration order within each capability defines fallback priority:
# the first source registered for a capability is the primary provider.

Rails.application.config.after_initialize do
  DataSourceRegistry.register(:polygon_stocks,
    name: "US Stocks — Polygon.io",
    icon: "show_chart",
    color: "indigo",
    gateway_class: MarketData::Gateways::PolygonGateway,
    job_class: SyncPriorityAssetsJob,
    job_args: %w[stock high],
    test_symbol: "AAPL",
    test_method: :fetch_price,
    integration_name: "Polygon.io",
    circuit_breaker_key: "stock",
    capabilities: %i[prices historical indices]
  )

  DataSourceRegistry.register(:finnhub_stocks,
    name: "US Stocks — Finnhub",
    icon: "show_chart",
    color: "cyan",
    gateway_class: MarketData::Gateways::FinnhubGateway,
    job_class: SyncPriorityAssetsJob,
    job_args: %w[stock high],
    test_symbol: "AAPL",
    test_method: :fetch_price,
    integration_name: "Finnhub",
    circuit_breaker_key: "finnhub",
    capabilities: %i[prices historical search news earnings]
  )

  DataSourceRegistry.register(:coingecko_crypto,
    name: "Crypto — CoinGecko",
    icon: "currency_bitcoin",
    color: "emerald",
    gateway_class: MarketData::Gateways::CoingeckoGateway,
    job_class: SyncPriorityAssetsJob,
    job_args: %w[crypto high],
    test_symbol: "BTC",
    test_method: :fetch_price,
    integration_name: "CoinGecko",
    circuit_breaker_key: "crypto",
    capabilities: %i[prices historical market_data]
  )

  DataSourceRegistry.register(:yahoo_bmv,
    name: "Mexican Stocks — Yahoo Finance",
    icon: "language",
    color: "sky",
    gateway_class: MarketData::Gateways::YahooFinanceGateway,
    job_class: SyncPriorityAssetsJob,
    job_args: %w[stock high],
    test_symbol: "GENIUSSACV.MX",
    test_method: :fetch_price,
    integration_name: "Yahoo Finance",
    circuit_breaker_key: "bmv",
    capabilities: %i[prices historical search indices]
  )

  DataSourceRegistry.register(:crypto_fear_greed,
    name: "Crypto F&G — Alternative.me",
    icon: "psychology",
    color: "purple",
    gateway_class: MarketData::Gateways::CryptoFearGreedGateway,
    job_class: RefreshFearGreedJob,
    job_args: [],
    test_symbol: nil,
    test_method: :fetch_price,
    integration_name: "Alternative.me",
    circuit_breaker_key: "crypto_fear_greed",
    capabilities: %i[sentiment]
  )

  DataSourceRegistry.register(:stock_fear_greed,
    name: "Stock F&G — CNN",
    icon: "psychology",
    color: "rose",
    gateway_class: MarketData::Gateways::StockFearGreedGateway,
    job_class: RefreshFearGreedJob,
    job_args: [],
    test_symbol: nil,
    test_method: :fetch_price,
    integration_name: "CNN",
    circuit_breaker_key: "stock_fear_greed",
    capabilities: %i[sentiment]
  )

  DataSourceRegistry.register(:polygon_news,
    name: "News — Polygon.io",
    icon: "newspaper",
    color: "slate",
    gateway_class: MarketData::Gateways::PolygonGateway,
    job_class: SyncNewsJob,
    job_args: [],
    test_symbol: nil,
    test_method: :fetch_price,
    integration_name: "Polygon.io",
    circuit_breaker_key: "polygon_news",
    capabilities: %i[news]
  )

  DataSourceRegistry.register(:yahoo_indices,
    name: "Market Indices — Yahoo Finance",
    icon: "monitoring",
    color: "teal",
    gateway_class: MarketData::Gateways::YahooFinanceGateway,
    job_class: SyncMarketIndicesJob,
    job_args: [],
    test_symbol: nil,
    test_method: :fetch_price,
    integration_name: "Yahoo Finance",
    circuit_breaker_key: "yahoo_indices",
    capabilities: %i[indices]
  )

  DataSourceRegistry.register(:alpha_vantage_fundamentals,
    name: "Fundamentals — Alpha Vantage",
    icon: "analytics",
    color: "orange",
    gateway_class: MarketData::Gateways::AlphaVantageGateway,
    job_class: SyncAllFundamentalsJob,
    job_args: [],
    test_symbol: "AAPL",
    test_method: :fetch_overview,
    integration_name: "Alpha Vantage",
    circuit_breaker_key: "alpha_vantage",
    capabilities: %i[fundamentals]
  )

  DataSourceRegistry.register(:polygon_earnings,
    name: "Earnings — Polygon.io",
    icon: "event_note",
    color: "violet",
    gateway_class: MarketData::Gateways::PolygonGateway,
    job_class: SyncEarningsJob,
    job_args: [],
    test_symbol: "AAPL",
    test_method: :fetch_price,
    integration_name: "Polygon.io",
    circuit_breaker_key: "polygon_earnings",
    capabilities: %i[earnings]
  )

  DataSourceRegistry.register(:fx_rates,
    name: "FX Rates",
    icon: "currency_exchange",
    color: "amber",
    gateway_class: MarketData::Gateways::FxRatesGateway,
    job_class: RefreshFxRatesJob,
    job_args: [],
    test_symbol: nil,
    test_method: :fetch_price,
    integration_name: "ExchangeRate",
    circuit_breaker_key: "fx",
    capabilities: %i[fx]
  )

  DataSourceRegistry.register(:banxico_cetes,
    name: "CETES — Banxico",
    icon: "account_balance",
    color: "lime",
    gateway_class: MarketData::Gateways::BanxicoGateway,
    job_class: SyncCetesJob,
    job_args: [],
    test_symbol: nil,
    test_method: :fetch_price,
    integration_name: "Banxico",
    circuit_breaker_key: "banxico",
    capabilities: %i[cetes]
  )

  DataSourceRegistry.register(:ai_intelligence,
    name: "AI Intelligence",
    icon: "psychology",
    color: "violet",
    gateway_class: MarketData::Gateways::LlmGateway,
    job_class: nil,
    job_args: [],
    test_symbol: nil,
    test_method: :fetch_price,
    integration_name: "AI Intelligence",
    circuit_breaker_key: "llm",
    capabilities: %i[llm]
  )
end
