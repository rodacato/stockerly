puts "Seeding database..."

# --- Users ---
admin = User.find_or_create_by!(email: "admin@stockerly.com") do |u|
  u.full_name = "Admin User"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :admin
  u.is_verified = true
  u.email_verified_at = Time.current
end

alex = User.find_or_create_by!(email: "alex.thompson@example.com") do |u|
  u.full_name = "Alex Thompson"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :user
  u.is_verified = true
  u.email_verified_at = Time.current
end

sarah = User.find_or_create_by!(email: "sarah.s@web3.io") do |u|
  u.full_name = "Sarah Chen"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :user
end

jdoe = User.find_or_create_by!(email: "john.doe@example.com") do |u|
  u.full_name = "John Doe"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :user
end

demo = User.find_or_create_by!(email: "demo@stockerly.com") do |u|
  u.full_name = "Demo Trader"
  u.password = "password123"
  u.password_confirmation = "password123"
  u.role = :user
  u.is_verified = true
  u.email_verified_at = Time.current
end

# --- Portfolios & AlertPreferences (created via event handlers in prod, manual in seeds) ---
[ admin, alex, sarah, jdoe, demo ].each do |user|
  Portfolio.find_or_create_by!(user: user) do |p|
    p.inception_date = user.created_at.to_date
  end
  AlertPreference.find_or_create_by!(user: user)
end

# --- Assets ---
aapl = Asset.find_or_create_by!(symbol: "AAPL") do |a|
  a.name = "Apple Inc."
  a.asset_type = :stock
  a.sector = "Technology"
  a.exchange = "NASDAQ"
  a.country = "US"
  a.data_source = "Polygon.io"
  a.current_price = 189.43
  a.change_percent_24h = 2.45
  a.market_cap = 2_940_000_000_000
  a.pe_ratio = 31.25
  a.div_yield = 0.52
  a.volume = 58_200_000
  a.shares_outstanding = 15_500_000_000
  a.price_updated_at = 2.minutes.ago
end

tsla = Asset.find_or_create_by!(symbol: "TSLA") do |a|
  a.name = "Tesla, Inc."
  a.asset_type = :stock
  a.sector = "Consumer Cyclical"
  a.exchange = "NASDAQ"
  a.country = "US"
  a.data_source = "Polygon.io"
  a.current_price = 176.54
  a.change_percent_24h = -1.12
  a.market_cap = 561_000_000_000
  a.pe_ratio = 62.80
  a.volume = 95_300_000
  a.shares_outstanding = 3_180_000_000
  a.price_updated_at = 2.minutes.ago
end

msft = Asset.find_or_create_by!(symbol: "MSFT") do |a|
  a.name = "Microsoft Corp."
  a.asset_type = :stock
  a.sector = "Technology"
  a.exchange = "NASDAQ"
  a.country = "US"
  a.data_source = "Polygon.io"
  a.current_price = 420.50
  a.change_percent_24h = 0.81
  a.market_cap = 3_120_000_000_000
  a.pe_ratio = 36.14
  a.div_yield = 0.72
  a.volume = 22_100_000
  a.shares_outstanding = 7_430_000_000
  a.price_updated_at = 2.minutes.ago
end

nvda = Asset.find_or_create_by!(symbol: "NVDA") do |a|
  a.name = "NVIDIA Corp."
  a.asset_type = :stock
  a.sector = "Technology"
  a.exchange = "NASDAQ"
  a.country = "US"
  a.data_source = "Polygon.io"
  a.current_price = 894.52
  a.change_percent_24h = 3.82
  a.market_cap = 2_210_000_000_000
  a.pe_ratio = 72.50
  a.div_yield = 0.02
  a.volume = 41_200_000
  a.shares_outstanding = 2_470_000_000
  a.price_updated_at = 2.minutes.ago
end

oke = Asset.find_or_create_by!(symbol: "OKE") do |a|
  a.name = "Oneok Inc."
  a.asset_type = :stock
  a.sector = "Energy"
  a.exchange = "NYSE"
  a.country = "US"
  a.data_source = "Polygon.io"
  a.current_price = 87.42
  a.change_percent_24h = 1.24
  a.market_cap = 51_200_000_000
  a.pe_ratio = 14.82
  a.div_yield = 4.48
  a.volume = 3_100_000
  a.shares_outstanding = 585_600_000
  a.price_updated_at = 5.minutes.ago
end

# New US stocks
googl = Asset.find_or_create_by!(symbol: "GOOGL") do |a|
  a.name = "Alphabet Inc."; a.asset_type = :stock; a.sector = "Technology"; a.exchange = "NASDAQ"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 174.98; a.change_percent_24h = 1.05; a.market_cap = 2_180_000_000_000
  a.pe_ratio = 25.10; a.volume = 28_400_000; a.price_updated_at = 2.minutes.ago
end
meta = Asset.find_or_create_by!(symbol: "META") do |a|
  a.name = "Meta Platforms"; a.asset_type = :stock; a.sector = "Technology"; a.exchange = "NASDAQ"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 502.30; a.change_percent_24h = -0.68; a.market_cap = 1_280_000_000_000
  a.pe_ratio = 33.20; a.volume = 18_600_000; a.price_updated_at = 2.minutes.ago
end
amzn = Asset.find_or_create_by!(symbol: "AMZN") do |a|
  a.name = "Amazon.com Inc."; a.asset_type = :stock; a.sector = "Consumer Cyclical"; a.exchange = "NASDAQ"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 186.49; a.change_percent_24h = 2.15; a.market_cap = 1_940_000_000_000
  a.pe_ratio = 60.75; a.volume = 35_200_000; a.price_updated_at = 2.minutes.ago
end
jpm = Asset.find_or_create_by!(symbol: "JPM") do |a|
  a.name = "JPMorgan Chase"; a.asset_type = :stock; a.sector = "Finance"; a.exchange = "NYSE"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 198.72; a.change_percent_24h = 0.54; a.market_cap = 571_000_000_000
  a.pe_ratio = 11.80; a.div_yield = 2.32; a.volume = 9_800_000; a.price_updated_at = 2.minutes.ago
end
jnj = Asset.find_or_create_by!(symbol: "JNJ") do |a|
  a.name = "Johnson & Johnson"; a.asset_type = :stock; a.sector = "Healthcare"; a.exchange = "NYSE"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 156.12; a.change_percent_24h = -0.22; a.market_cap = 375_000_000_000
  a.pe_ratio = 22.40; a.div_yield = 3.05; a.volume = 7_100_000; a.price_updated_at = 2.minutes.ago
end
ko = Asset.find_or_create_by!(symbol: "KO") do |a|
  a.name = "Coca-Cola Co."; a.asset_type = :stock; a.sector = "Consumer"; a.exchange = "NYSE"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 60.85; a.change_percent_24h = 0.33; a.market_cap = 263_000_000_000
  a.pe_ratio = 24.90; a.div_yield = 3.10; a.volume = 12_500_000; a.price_updated_at = 2.minutes.ago
end
pg = Asset.find_or_create_by!(symbol: "PG") do |a|
  a.name = "Procter & Gamble"; a.asset_type = :stock; a.sector = "Consumer"; a.exchange = "NYSE"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 162.40; a.change_percent_24h = 0.18; a.market_cap = 382_000_000_000
  a.pe_ratio = 26.10; a.div_yield = 2.45; a.volume = 6_800_000; a.price_updated_at = 2.minutes.ago
end

# US ETFs
qqq = Asset.find_or_create_by!(symbol: "QQQ") do |a|
  a.name = "Invesco QQQ Trust"; a.asset_type = :etf; a.exchange = "NASDAQ"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 438.20; a.change_percent_24h = 1.42; a.volume = 42_100_000; a.price_updated_at = 2.minutes.ago
end
spy = Asset.find_or_create_by!(symbol: "SPY") do |a|
  a.name = "SPDR S&P 500 ETF"; a.asset_type = :etf; a.exchange = "NYSE"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 521.45; a.change_percent_24h = 0.58; a.volume = 65_300_000; a.price_updated_at = 2.minutes.ago
end
voo = Asset.find_or_create_by!(symbol: "VOO") do |a|
  a.name = "Vanguard S&P 500"; a.asset_type = :etf; a.exchange = "NYSE"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 479.10; a.change_percent_24h = 0.55; a.volume = 4_200_000; a.price_updated_at = 2.minutes.ago
end
vti = Asset.find_or_create_by!(symbol: "VTI") do |a|
  a.name = "Vanguard Total Stock"; a.asset_type = :etf; a.exchange = "NYSE"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 262.80; a.change_percent_24h = 0.48; a.volume = 3_500_000; a.price_updated_at = 2.minutes.ago
end
arkk = Asset.find_or_create_by!(symbol: "ARKK") do |a|
  a.name = "ARK Innovation ETF"; a.asset_type = :etf; a.exchange = "NYSE"; a.country = "US"
  a.data_source = "Polygon.io"; a.current_price = 49.25; a.change_percent_24h = -1.85; a.volume = 8_900_000; a.price_updated_at = 2.minutes.ago
end

# Mexico (BMV) — prices via Yahoo Finance
genius = Asset.find_or_create_by!(symbol: "GENIUSSACV.MX") do |a|
  a.name = "Genius Sports SAB"; a.asset_type = :stock; a.sector = "Technology"; a.exchange = "BMV"; a.country = "MX"
  a.data_source = "Yahoo Finance"; a.current_price = 32.50; a.change_percent_24h = 0.92; a.volume = 450_000; a.price_updated_at = 2.minutes.ago
end
ivvpeso = Asset.find_or_create_by!(symbol: "IVVPESO.MX") do |a|
  a.name = "iShares S&P 500 MXN"; a.asset_type = :etf; a.exchange = "BMV"; a.country = "MX"
  a.data_source = "Yahoo Finance"; a.current_price = 645.20; a.change_percent_24h = 0.75; a.volume = 1_200_000; a.price_updated_at = 2.minutes.ago
end

# Crypto
btc = Asset.find_or_create_by!(symbol: "BTC") do |a|
  a.name = "Bitcoin"
  a.asset_type = :crypto
  a.data_source = "CoinGecko API"
  a.current_price = 64_231.00
  a.change_percent_24h = 0.85
  a.market_cap = 1_260_000_000_000
  a.price_updated_at = 1.minute.ago
end

eth = Asset.find_or_create_by!(symbol: "ETH") do |a|
  a.name = "Ethereum"
  a.asset_type = :crypto
  a.data_source = "CoinGecko API"
  a.current_price = 3_450.00
  a.change_percent_24h = -0.45
  a.market_cap = 415_000_000_000
  a.sync_status = :disabled
  a.price_updated_at = 1.hour.ago
end

sol = Asset.find_or_create_by!(symbol: "SOL") do |a|
  a.name = "Solana"
  a.asset_type = :crypto
  a.data_source = "CoinGecko API"
  a.current_price = 142.80
  a.change_percent_24h = 2.10
  a.sync_status = :active
  a.price_updated_at = 30.minutes.ago
end

# Indices
vix = Asset.find_or_create_by!(symbol: "VIX") do |a|
  a.name = "CBOE Volatility Index"
  a.asset_type = :index
  a.exchange = "CBOE"
  a.country = "US"
  a.current_price = 14.33
  a.change_percent_24h = -1.22
  a.price_updated_at = 10.minutes.ago
end


# --- Asset Logos (backfill — safe for re-runs) ---
# Clearbit logo API is defunct. Only crypto logos (CoinGecko) are reliable.
# Stock/ETF badges use the styled text fallback in _asset_badge.html.erb.
{
  "BTC"   => "https://assets.coingecko.com/coins/images/1/small/bitcoin.png",
  "ETH"   => "https://assets.coingecko.com/coins/images/279/small/ethereum.png",
  "SOL"   => "https://assets.coingecko.com/coins/images/4128/small/solana.png"
}.each do |symbol, url|
  Asset.find_by(symbol: symbol)&.update!(logo_url: url)
end
# Clear any stale Clearbit URLs
Asset.where("logo_url LIKE ?", "%clearbit%").update_all(logo_url: nil)

# --- Trades & Positions for Alex ---
portfolio = alex.portfolio
portfolio.update!(buying_power: 8_240.15, inception_date: Date.new(2023, 1, 12))

unless Position.where(portfolio: portfolio).exists?
  [
    { asset: aapl, shares: 50,  price: 150.20, currency: "USD", date: 1.year.ago },
    { asset: msft, shares: 30,  price: 280.15, currency: "USD", date: 10.months.ago },
    { asset: tsla, shares: 20,  price: 242.50, currency: "USD", date: 8.months.ago },
    { asset: nvda, shares: 15,  price: 420.00, currency: "USD", date: 6.months.ago },
    { asset: genius, shares: 200, price: 25.50, currency: "MXN", date: 3.months.ago }
  ].each do |t|
    position = Position.create!(
      portfolio: portfolio, asset: t[:asset], shares: t[:shares],
      avg_cost: t[:price], currency: t[:currency], status: :open, opened_at: t[:date]
    )
    Trade.create!(
      portfolio: portfolio, asset: t[:asset], position: position,
      side: :buy, shares: t[:shares], price_per_share: t[:price],
      total_amount: t[:shares] * t[:price], currency: t[:currency],
      executed_at: t[:date]
    )
  end
end

# --- Watchlist for Alex ---
[ aapl, tsla, btc, nvda, msft ].each do |asset|
  WatchlistItem.find_or_create_by!(user: alex, asset: asset) do |w|
    w.entry_price = asset.current_price
  end
end

# --- Alert Rules for Alex ---
unless AlertRule.where(user: alex).exists?
  AlertRule.create!(user: alex, asset_symbol: "AAPL",    condition: :price_crosses_above, threshold_value: 195.00, status: :active)
  AlertRule.create!(user: alex, asset_symbol: "TSLA",    condition: :rsi_oversold,        threshold_value: 30,     status: :paused)
  AlertRule.create!(user: alex, asset_symbol: "BTC/USD", condition: :day_change_percent,  threshold_value: 5.0,    status: :active)
end

# --- Alert Events ---
unless AlertEvent.where(user: alex).exists?
  AlertEvent.create!(user: alex, asset_symbol: "MSFT", message: "Price crossed above resistance at $420.50", event_status: :triggered, triggered_at: 2.minutes.ago)
  AlertEvent.create!(user: alex, asset_symbol: "AMZN", message: "Fell below target of $175.00",              event_status: :triggered, triggered_at: 15.minutes.ago)
  AlertEvent.create!(user: alex, asset_symbol: "NVDA", message: "24h volume spiked by 12.5%",                event_status: :settled,   triggered_at: 1.hour.ago)
  AlertEvent.create!(user: alex, asset_symbol: "META", message: "Golden cross pattern detected on 4H chart", event_status: :settled,   triggered_at: 2.hours.ago)
end

# --- Alert Preferences ---
alex.alert_preference.update!(browser_push: true, email_digest: true, sms_notifications: false)

# --- Market Indices ---
MarketIndex.find_or_create_by!(symbol: "SPX") do |i|
  i.name = "S&P 500"
  i.value = 5_214.33
  i.change_percent = 0.42
  i.exchange = "NYSE"
  i.is_open = true
end
MarketIndex.find_or_create_by!(symbol: "NDX") do |i|
  i.name = "NASDAQ 100"
  i.value = 18_322.40
  i.change_percent = 1.15
  i.exchange = "NASDAQ"
  i.is_open = true
end
MarketIndex.find_or_create_by!(symbol: "DJI") do |i|
  i.name = "DOW JONES"
  i.value = 39_127.14
  i.change_percent = -0.12
  i.exchange = "NYSE"
  i.is_open = true
end
MarketIndex.find_or_create_by!(symbol: "UKX") do |i|
  i.name = "FTSE 100"
  i.value = 7_935.09
  i.change_percent = 0.28
  i.exchange = "LSE"
  i.is_open = false
end
MarketIndex.find_or_create_by!(symbol: "IPC") do |i|
  i.name = "IPC Mexico"
  i.value = 52_180.50
  i.change_percent = -0.30
  i.exchange = "BMV"
  i.is_open = false
end
MarketIndex.find_or_create_by!(symbol: "VIX") do |i|
  i.name = "CBOE Volatility"
  i.value = 14.33
  i.change_percent = -2.15
  i.exchange = "CBOE"
  i.is_open = true
end

# --- Trend Scores ---
# Computed by CalculateTrendScoresJob from real price history.
# Run: CalculateTrendScoresJob.perform_now after seeding to populate initial scores.

# --- Earnings Events ---
# Earnings are synced weekly from Polygon.io via SyncEarningsJob.
# Run: SyncEarningsJob.perform_now after seeding to populate initial data.

# --- Fixed Income (CETES) ---
Asset.find_or_create_by!(symbol: "CETE28D") do |a|
  a.name = "CETES 28 Dias"
  a.asset_type = :fixed_income
  a.current_price = 10.0
  a.yield_rate = 11.15
  a.maturity_date = 28.days.from_now.to_date
  a.face_value = 10.0
  a.exchange = "Banxico"
  a.country = "MX"
  a.sync_status = :disabled
end
Asset.find_or_create_by!(symbol: "CETE364D") do |a|
  a.name = "CETES 364 Dias"
  a.asset_type = :fixed_income
  a.current_price = 10.0
  a.yield_rate = 10.50
  a.maturity_date = 364.days.from_now.to_date
  a.face_value = 10.0
  a.exchange = "Banxico"
  a.country = "MX"
  a.sync_status = :disabled
end

# --- News Articles ---
unless NewsArticle.exists?
  NewsArticle.create!(
    title: "Apple's Vision Pro Sales Exceed Expectations in First Quarter",
    summary: "New supply chain data suggests strong demand for the spatial computing headset across institutional markets.",
    source: "Bloomberg", related_ticker: "AAPL", published_at: 2.hours.ago,
    image_url: "https://placehold.co/120x80", url: "https://example.com/aapl-vision-pro"
  )
  NewsArticle.create!(
    title: "Microsoft Announces Multi-Billion Dollar AI Infrastructure Plan",
    summary: "The tech giant plans to double its data center capacity to support growing enterprise AI demands globally.",
    source: "Reuters", related_ticker: "MSFT", published_at: 5.hours.ago,
    image_url: "https://placehold.co/120x80", url: "https://example.com/msft-ai"
  )
  NewsArticle.create!(
    title: "Tesla Shifts Focus to Next-Gen Platform for Affordable EV",
    summary: "The company is reportedly restructuring its autonomous AI unit as it pivots toward a sub-$25,000 electric vehicle.",
    source: "WSJ", related_ticker: "TSLA", published_at: 8.hours.ago,
    image_url: "https://placehold.co/120x80", url: "https://example.com/tsla-ev"
  )
end

# --- Portfolio Snapshots for Alex ---
unless PortfolioSnapshot.where(portfolio: portfolio).exists?
  5.downto(1).each do |days_ago|
    PortfolioSnapshot.create!(
      portfolio: portfolio,
      date: days_ago.days.ago.to_date,
      total_value: portfolio.total_value + rand(-500.0..500.0).round(2),
      cash_value: portfolio.buying_power,
      invested_value: (portfolio.total_value - portfolio.buying_power + rand(-300.0..300.0)).round(2)
    )
  end
end

# --- FX Rates ---
FxRate.find_or_create_by!(base_currency: "USD", quote_currency: "EUR") do |r|
  r.rate = 0.92
  r.fetched_at = 1.hour.ago
end
FxRate.find_or_create_by!(base_currency: "USD", quote_currency: "MXN") do |r|
  r.rate = 17.25
  r.fetched_at = 1.hour.ago
end
FxRate.find_or_create_by!(base_currency: "USD", quote_currency: "GBP") do |r|
  r.rate = 0.79
  r.fetched_at = 1.hour.ago
end

# --- Dividends ---
unless Dividend.exists?
  aapl_div = Dividend.create!(asset: aapl, ex_date: 1.month.ago.to_date, pay_date: 3.weeks.ago.to_date, amount_per_share: 0.24, currency: "USD")
  DividendPayment.create!(portfolio: portfolio, dividend: aapl_div, shares_held: 50, total_amount: 12.00, received_at: 3.weeks.ago)
end

# --- Notifications for Alex ---
unless Notification.where(user: alex).exists?
  Notification.create!(user: alex, title: "MSFT crossed $420.50", body: "Your price alert for Microsoft was triggered.", notification_type: :alert_triggered, notifiable: AlertEvent.first)
  Notification.create!(user: alex, title: "AAPL earnings tomorrow", body: "Apple reports Q4 earnings after market close.", notification_type: :earnings_reminder)
end

# --- System Logs ---
unless SystemLog.exists?
  SystemLog.create!(task_name: "FX Rate Update",       module_name: "Finance",     severity: :success, duration_seconds: 1.2)
  SystemLog.create!(task_name: "Shopify Price Sync",    module_name: "Marketplace", severity: :error,   duration_seconds: 5.4, error_message: "Auth Exception: Connection timeout after 5000ms")
  SystemLog.create!(task_name: "Inventory Audit",       module_name: "Warehouse",   severity: :warning, duration_seconds: 12.8, error_message: "Partial sync: 3 items skipped")
  SystemLog.create!(task_name: "Daily Backup",          module_name: "Core",        severity: :success, duration_seconds: 45.0)
  SystemLog.create!(task_name: "User Session Clean-up", module_name: "Auth",        severity: :success, duration_seconds: 0.8)
end

# --- Integrations ---
Integration.find_or_create_by!(provider_name: "Polygon.io") do |i|
  i.provider_type = "Stocks & Forex"
  i.api_key_encrypted = ENV.fetch("POLYGON_API_KEY", "pk_live_abc123xyz789")
  i.connection_status = :connected
  i.last_sync_at = 2.minutes.ago
  i.max_requests_per_minute = 5
  i.daily_call_limit = 500
end
Integration.find_or_create_by!(provider_name: "CoinGecko") do |i|
  i.provider_type = "Cryptocurrency"
  i.api_key_encrypted = ENV.fetch("COINGECKO_API_KEY", "cg_demo_key_456def")
  i.connection_status = :syncing
  i.last_sync_at = 1.hour.ago
  i.max_requests_per_minute = 30
  i.daily_call_limit = 10_000
end
Integration.find_or_create_by!(provider_name: "Yahoo Finance") do |i|
  i.provider_type = "Mexican Stocks & ETFs"
  i.requires_api_key = false
  i.connection_status = :connected
  i.last_sync_at = Time.current
  i.daily_call_limit = 2_000
end
Integration.find_or_create_by!(provider_name: "Alternative.me") do |i|
  i.provider_type = "Sentiment"
  i.requires_api_key = false
  i.connection_status = :connected
  i.last_sync_at = 1.day.ago
  i.daily_call_limit = 100
end
Integration.find_or_create_by!(provider_name: "CNN") do |i|
  i.provider_type = "Sentiment"
  i.requires_api_key = false
  i.connection_status = :connected
  i.last_sync_at = 1.day.ago
  i.daily_call_limit = 100
end

Integration.find_or_create_by!(provider_name: "Alpha Vantage") do |i|
  i.provider_type = "Fundamentals"
  i.api_key_encrypted = ENV.fetch("ALPHA_VANTAGE_API_KEY", "av_demo_key_789")
  i.connection_status = :connected
  i.last_sync_at = 1.day.ago
  i.max_requests_per_minute = 5
  i.daily_call_limit = 25
end
Integration.find_or_create_by!(provider_name: "FMP") do |i|
  i.provider_type = "Dividends & Splits"
  i.api_key_encrypted = ENV.fetch("FMP_API_KEY", "fmp_demo_key_123")
  i.requires_api_key = true
  i.connection_status = :connected
  i.last_sync_at = 1.week.ago
  i.max_requests_per_minute = 10
  i.daily_call_limit = 250
end

# --- Asset Fundamentals (sample AAPL OVERVIEW) ---
AssetFundamental.find_or_create_by!(asset: aapl, period_label: "OVERVIEW") do |f|
  f.metrics = {
    "symbol" => "AAPL", "name" => "Apple Inc.", "sector" => "Technology",
    "exchange" => "NASDAQ", "currency" => "USD", "country" => "USA",
    "eps" => "6.07", "book_value" => "3.95", "dividend_per_share" => "0.96",
    "dividend_yield" => "0.0052", "profit_margin" => "0.2461",
    "operating_margin" => "0.3031", "return_on_equity" => "1.5700",
    "return_on_assets" => "0.2720", "revenue_ttm" => "391035000000",
    "ebitda" => "131561000000", "beta" => "1.24",
    "market_cap" => "2940000000000", "shares_outstanding" => "15500000000",
    "pe_ratio" => "31.25", "price_to_book" => "47.96",
    "price_to_sales" => "7.52", "ev_to_ebitda" => "23.45",
    "revenue_per_share" => "25.23", "quarterly_earnings_growth" => "0.10",
    "quarterly_revenue_growth" => "0.05", "fifty_two_week_high" => "199.62",
    "fifty_two_week_low" => "164.08", "forward_pe" => "28.50",
    "peg_ratio" => "2.15", "analyst_target_price" => "200.00"
  }
  f.source = "api_overview"
  f.calculated_at = 1.day.ago
end

# --- Fear & Greed Readings ---
unless FearGreedReading.exists?
  FearGreedReading.create!(index_type: "crypto", value: 25, classification: "Fear", source: "alternative.me", fetched_at: 6.hours.ago)
  FearGreedReading.create!(index_type: "stocks", value: 62, classification: "Greed", source: "cnn", fetched_at: 6.hours.ago)
end

# --- Audit Logs ---
unless AuditLog.exists?
  AuditLog.create!(user: admin, action: "admin.assets.create", auditable: aapl, changes_data: { after: { symbol: "AAPL" } }, ip_address: "127.0.0.1")
  AuditLog.create!(user: admin, action: "admin.integrations.connect", auditable: Integration.first, changes_data: { after: { provider: "Polygon.io" } }, ip_address: "127.0.0.1")
end

puts "Seeded: #{User.count} users, #{Asset.count} assets, #{Position.count} positions, #{Trade.count} trades, #{AlertRule.count} alert rules, #{EarningsEvent.count} earnings, #{NewsArticle.count} news, #{Notification.count} notifications, #{PortfolioSnapshot.count} snapshots, #{FxRate.count} FX rates, #{Dividend.count} dividends."
