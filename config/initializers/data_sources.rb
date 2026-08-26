# Registers all known data sources at boot time.
# New sources should be added here so they appear in admin and are
# resolvable by SyncIntegrationJob.
#
# Registration order within each capability defines fallback priority:
# the first source registered for a capability is the primary provider.

Rails.application.config.after_initialize do
  DataSourceRegistry.register(:alpaca_us,
    name: "US Stocks — Alpaca",
    icon: "candlestick_chart",
    color: "amber",
    gateway_class: MarketData::Gateways::AlpacaGateway,
    job_class: SyncPriorityAssetsJob,
    job_args: %w[stock high],
    test_symbol: "AAPL",
    test_method: :fetch_historical,
    integration_name: "Alpaca",
    circuit_breaker_key: "alpaca",
    capabilities: %i[historical news]
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

  DataSourceRegistry.register(:databursatil_bmv,
    name: "Mexican Stocks — DataBursatil",
    icon: "account_balance",
    color: "rose",
    gateway_class: MarketData::Gateways::DataBursatilGateway,
    job_class: SyncPriorityAssetsJob,
    job_args: %w[stock high],
    test_symbol: "GFNORTEO.MX",
    test_method: :fetch_price,
    integration_name: "DataBursatil",
    circuit_breaker_key: "databursatil",
    capabilities: %i[prices historical intraday]
  )

  DataSourceRegistry.register(:crypto_fear_greed,
    name: "Crypto F&G — Alternative.me",
    icon: "psychology",
    color: "purple",
    gateway_class: MarketData::Gateways::CryptoFearGreedGateway,
    job_class: RefreshFearGreedJob,
    job_args: [],
    test_symbol: nil,
    test_method: :fetch_index,
    integration_name: "Alternative.me",
    circuit_breaker_key: "crypto_fear_greed",
    capabilities: %i[sentiment]
  )

  DataSourceRegistry.register(:yfinance_bridge,
    name: "Yahoo Finance — via the yfinance bridge",
    icon: "monitoring",
    color: "teal",
    gateway_class: MarketData::Gateways::YfinanceGateway,
    job_class: SyncMarketIndicesJob,
    job_args: [],
    test_symbol: "^MXX",
    test_method: :fetch_price,
    integration_name: "Yahoo Finance",
    circuit_breaker_key: "yfinance",
    # BMV earnings are served through an explicit route in SyncEarnings, not
    # through a chain: declaring :earnings here would put the bridge in the US
    # chain too, where Finnhub and Polygon already answer.
    capabilities: %i[prices historical indices dividends splits]
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

  DataSourceRegistry.register(:fx_rates,
    name: "FX Rates",
    icon: "currency_exchange",
    color: "amber",
    gateway_class: MarketData::Gateways::FxRatesGateway,
    job_class: RefreshFxRatesJob,
    job_args: [],
    test_symbol: nil,
    test_method: :refresh_rates,
    integration_name: "ExchangeRate",
    circuit_breaker_key: "fx",
    capabilities: %i[fx_current]
  )

  DataSourceRegistry.register(:banxico_fx,
    name: "Tipo de cambio — Banxico FIX",
    icon: "currency_exchange",
    color: "lime",
    gateway_class: MarketData::Gateways::BanxicoGateway,
    job_class: SyncFxHistoryJob,
    job_args: [],
    test_symbol: nil,
    test_method: :fetch_fx_fixes,
    integration_name: "Banxico",
    health_check: true,
    circuit_breaker_key: "banxico",
    capabilities: %i[fx_history]
  )

  DataSourceRegistry.register(:banxico_cetes,
    name: "CETES — Banxico",
    icon: "account_balance",
    color: "lime",
    gateway_class: MarketData::Gateways::BanxicoGateway,
    job_class: SyncCetesJob,
    job_args: [],
    test_symbol: nil,
    test_method: :fetch_auctions,
    integration_name: "Banxico",
    circuit_breaker_key: "banxico",
    capabilities: %i[cetes]
  )
end
