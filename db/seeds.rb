puts "Seeding database..."

# --- Market holidays (BMV + Banxico + NYSE/NASDAQ) ---
load Rails.root.join("db/seeds/market_holidays.rb")

# --- Site Configuration ---
SiteConfig.find_or_create_by!(key: "registration_open") do |c|
  c.value = "false"
end
SiteConfig.find_or_create_by!(key: "maintenance_mode") do |c|
  c.value = "false"
end

# --- Demo Users (development only) ---
# Admin is NOT seeded — use the Setup Wizard at /setup on first boot.
# The wizard creates your admin account securely with your own credentials.
# Demo users are only created in development to avoid blocking /setup in production.

if Rails.env.development?
  alex = User.find_or_create_by!(email: "alex.thompson@example.com") do |u|
    u.full_name = "Alex Thompson"
    u.password = "password123"
    u.password_confirmation = "password123"
    u.role = :user
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
  end

  # --- Portfolios & AlertPreferences (created via event handlers in prod, manual in seeds) ---
  [ alex, sarah, jdoe, demo ].each do |user|
    Portfolio.find_or_create_by!(user: user) do |p|
      p.inception_date = user.created_at.to_date
    end
    AlertPreference.find_or_create_by!(user: user)
  end
end

# --- Assets ---
# Identity (name, type, sector, exchange, country, currency) comes from the one
# catalogue the seed task also walks. Only the market fixture below is dev's own —
# prices and fundamentals a dev instance needs to render something.
Administration::UseCases::Assets::SeedCatalog.call

DEV_MARKET_DATA = {
  "AAPL" => { current_price: 189.43, market_cap: 2_940_000_000_000, pe_ratio: 31.25, div_yield: 0.52, volume: 58_200_000, shares_outstanding: 15_500_000_000, price_updated_at: 2.minutes.ago },
  "TSLA" => { current_price: 176.54, market_cap: 561_000_000_000, pe_ratio: 62.80, volume: 95_300_000, shares_outstanding: 3_180_000_000, price_updated_at: 2.minutes.ago },
  "MSFT" => { current_price: 420.50, market_cap: 3_120_000_000_000, pe_ratio: 36.14, div_yield: 0.72, volume: 22_100_000, shares_outstanding: 7_430_000_000, price_updated_at: 2.minutes.ago },
  "NVDA" => { current_price: 894.52, market_cap: 2_210_000_000_000, pe_ratio: 72.50, div_yield: 0.02, volume: 41_200_000, shares_outstanding: 2_470_000_000, price_updated_at: 2.minutes.ago },
  "OKE" => { current_price: 87.42, market_cap: 51_200_000_000, pe_ratio: 14.82, div_yield: 4.48, volume: 3_100_000, shares_outstanding: 585_600_000, price_updated_at: 5.minutes.ago },
  "GOOGL" => { current_price: 174.98, market_cap: 2_180_000_000_000, pe_ratio: 25.10, volume: 28_400_000, price_updated_at: 2.minutes.ago },
  "META" => { current_price: 502.30, market_cap: 1_280_000_000_000, pe_ratio: 33.20, volume: 18_600_000, price_updated_at: 2.minutes.ago },
  "AMZN" => { current_price: 186.49, market_cap: 1_940_000_000_000, pe_ratio: 60.75, volume: 35_200_000, price_updated_at: 2.minutes.ago },
  "JPM" => { current_price: 198.72, market_cap: 571_000_000_000, pe_ratio: 11.80, div_yield: 2.32, volume: 9_800_000, price_updated_at: 2.minutes.ago },
  "JNJ" => { current_price: 156.12, market_cap: 375_000_000_000, pe_ratio: 22.40, div_yield: 3.05, volume: 7_100_000, price_updated_at: 2.minutes.ago },
  "KO" => { current_price: 60.85, market_cap: 263_000_000_000, pe_ratio: 24.90, div_yield: 3.10, volume: 12_500_000, price_updated_at: 2.minutes.ago },
  "PG" => { current_price: 162.40, market_cap: 382_000_000_000, pe_ratio: 26.10, div_yield: 2.45, volume: 6_800_000, price_updated_at: 2.minutes.ago },
  "QQQ" => { current_price: 438.20, volume: 42_100_000, price_updated_at: 2.minutes.ago },
  "SPY" => { current_price: 521.45, volume: 65_300_000, price_updated_at: 2.minutes.ago },
  "VOO" => { current_price: 479.10, volume: 4_200_000, price_updated_at: 2.minutes.ago },
  "VTI" => { current_price: 262.80, volume: 3_500_000, price_updated_at: 2.minutes.ago },
  "ARKK" => { current_price: 49.25, volume: 8_900_000, price_updated_at: 2.minutes.ago },
  "GENIUSSACV.MX" => { currency: "MXN", data_source: "Yahoo Finance", current_price: 32.50, volume: 450_000, price_updated_at: 2.minutes.ago },
  "IVVPESO.MX" => { currency: "MXN", data_source: "Yahoo Finance", current_price: 645.20, volume: 1_200_000, price_updated_at: 2.minutes.ago },
  "BTC" => { data_source: "CoinGecko API", current_price: 64_231.00, market_cap: 1_260_000_000_000, price_updated_at: 1.minute.ago },
  "ETH" => { data_source: "CoinGecko API", current_price: 3_450.00, market_cap: 415_000_000_000, sync_status: :disabled, price_updated_at: 1.hour.ago },
  "SOL" => { data_source: "CoinGecko API", current_price: 142.80, sync_status: :active, price_updated_at: 30.minutes.ago },
  "VIX" => { current_price: 14.33, price_updated_at: 10.minutes.ago }
}.freeze

DEV_MARKET_DATA.each do |symbol, market|
  Asset.find_by(symbol: symbol)&.update!(market)
end

aapl = Asset.find_by!(symbol: "AAPL")
tsla = Asset.find_by!(symbol: "TSLA")
msft = Asset.find_by!(symbol: "MSFT")
nvda = Asset.find_by!(symbol: "NVDA")
Asset.find_by!(symbol: "OKE")
Asset.find_by!(symbol: "GOOGL")
Asset.find_by!(symbol: "META")
Asset.find_by!(symbol: "AMZN")
Asset.find_by!(symbol: "JPM")
Asset.find_by!(symbol: "JNJ")
Asset.find_by!(symbol: "KO")
Asset.find_by!(symbol: "PG")
Asset.find_by!(symbol: "QQQ")
Asset.find_by!(symbol: "SPY")
Asset.find_by!(symbol: "VOO")
Asset.find_by!(symbol: "VTI")
Asset.find_by!(symbol: "ARKK")
genius = Asset.find_by!(symbol: "GENIUSSACV.MX")
Asset.find_by!(symbol: "IVVPESO.MX")
btc = Asset.find_by!(symbol: "BTC")
Asset.find_by!(symbol: "ETH")
Asset.find_by!(symbol: "SOL")
Asset.find_by!(symbol: "VIX")


# --- FX Rates ---
# Before any demo portfolio, not after: valuing a mixed-currency portfolio
# converts, and Portfolio#convert raises rather than guessing. Both directions
# of USD/MXN are seeded because the lookup is by exact pair — it does not
# invert one into the other.
{ [ "USD", "EUR" ] => 0.92, [ "USD", "MXN" ] => 17.25, [ "MXN", "USD" ] => 0.058,
  [ "USD", "GBP" ] => 0.79 }.each do |(base, quote), rate|
  FxRate.find_or_create_by!(base_currency: base, quote_currency: quote) do |r|
    r.rate = rate
    r.fetched_at = 1.hour.ago
  end
end

# --- Demo data for Alex (development only) ---
if Rails.env.development? && (alex = User.find_by(email: "alex.thompson@example.com"))
  portfolio = alex.portfolio
  portfolio.update!(inception_date: Date.new(2023, 1, 12))

  unless Position.exists?(portfolio: portfolio)
    [
      { asset: aapl, shares: 50,  price: 150.20, currency: "USD", date: 1.year.ago },
      { asset: msft, shares: 30,  price: 280.15, currency: "USD", date: 10.months.ago },
      { asset: tsla, shares: 20,  price: 242.50, currency: "USD", date: 8.months.ago },
      { asset: nvda, shares: 15,  price: 420.00, currency: "USD", date: 6.months.ago },
      { asset: genius, shares: 200, price: 25.50, currency: "MXN", date: 3.months.ago }
    ].each do |t|
      position = Position.create!(
        portfolio: portfolio, asset: t[:asset], shares: t[:shares],
        avg_cost: t[:price], status: :open, opened_at: t[:date]
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
  unless AlertRule.exists?(user: alex)
    AlertRule.create!(user: alex, asset_symbol: "AAPL",    condition: :price_crosses_above, threshold_value: 195.00, status: :active)
    AlertRule.create!(user: alex, asset_symbol: "TSLA",    condition: :rsi_oversold,        threshold_value: 30,     status: :paused)
    AlertRule.create!(user: alex, asset_symbol: "BTC/USD", condition: :day_change_percent,  threshold_value: 5.0,    status: :active)
  end

  # --- Alert Events ---
  unless AlertEvent.exists?(user: alex)
    AlertEvent.create!(user: alex, asset_symbol: "MSFT", message: "Price crossed above resistance at $420.50", event_status: :triggered, triggered_at: 2.minutes.ago)
    AlertEvent.create!(user: alex, asset_symbol: "AMZN", message: "Fell below target of $175.00",              event_status: :triggered, triggered_at: 15.minutes.ago)
    AlertEvent.create!(user: alex, asset_symbol: "NVDA", message: "24h volume spiked by 12.5%",                event_status: :settled,   triggered_at: 1.hour.ago)
    AlertEvent.create!(user: alex, asset_symbol: "META", message: "Golden cross pattern detected on 4H chart", event_status: :settled,   triggered_at: 2.hours.ago)
  end

  # --- Alert Preferences ---
  alex.alert_preference.update!(email_digest: true, urgent_email: false)

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
# Earnings are synced weekly via SyncEarningsJob.
# Run: SyncEarningsJob.perform_now after seeding to populate initial data.

# --- Fixed Income (CETES) ---
Asset.find_or_create_by!(symbol: "CETES_28D") do |a|
  a.name = "CETES 28 Dias"
  a.asset_type = :fixed_income
  a.current_price = 10.0
  a.yield_rate = 11.15
  a.maturity_date = 28.days.from_now.to_date
  a.face_value = 10.0
  a.exchange = "Banxico"
  a.country = "MX"
  a.currency = "MXN"
  a.sync_status = :disabled
end
Asset.find_or_create_by!(symbol: "CETES_364D") do |a|
  a.name = "CETES 364 Dias"
  a.asset_type = :fixed_income
  a.current_price = 10.0
  a.yield_rate = 10.50
  a.maturity_date = 364.days.from_now.to_date
  a.face_value = 10.0
  a.exchange = "Banxico"
  a.country = "MX"
  a.currency = "MXN"
  a.sync_status = :disabled
end

if Rails.env.development?
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
end

  # --- Portfolio Snapshots for Alex ---
  unless PortfolioSnapshot.exists?(portfolio: portfolio)
    5.downto(1).each do |days_ago|
      # The currency is part of the reading, not decoration: a snapshot without
      # one cannot be compared to the next.
      PortfolioSnapshot.create!(
        portfolio: portfolio,
        date: days_ago.days.ago.to_date,
        currency: alex.preferred_currency,
        total_value: portfolio.total_value + rand(-500.0..500.0).round(2)
      )
    end
  end

  # --- Dividends ---
  unless Dividend.exists?
    aapl_div = Dividend.create!(asset: aapl, ex_date: 1.month.ago.to_date, pay_date: 3.weeks.ago.to_date, amount_per_share: 0.24, currency: "USD")
    DividendPayment.create!(portfolio: portfolio, dividend: aapl_div, shares_held: 50, total_amount: 12.00)
  end

  # --- Notifications for Alex ---
  unless Notification.exists?(user: alex)
    Notification.create!(user: alex, title: "MSFT crossed $420.50", body: "Your price alert for Microsoft was triggered.", notification_type: :alert_triggered, notifiable: AlertEvent.first)
    Notification.create!(user: alex, title: "AAPL earnings tomorrow", body: "Apple reports Q4 earnings after market close.", notification_type: :earnings_reminder)
  end

  # --- Audit Logs ---
  unless AuditLog.exists?
    AuditLog.create!(user: alex, action: "admin.assets.create", auditable: aapl, changes_data: { after: { symbol: "AAPL" } }, ip_address: "127.0.0.1")
    AuditLog.create!(user: alex, action: "admin.integrations.connect", auditable: Integration.first, changes_data: { after: { provider: "Alpaca" } }, ip_address: "127.0.0.1")
  end
end # Rails.env.development? (alex demo data)

# --- Integrations ---
# Synced from DataSourceRegistry definitions. Defaults defined in lib/tasks/sync.rake.
# API keys are NOT seeded — configure them via Admin > Integrations.
Rake::Task["stockerly:sync"].invoke

if Rails.env.development?
  # --- System Logs ---
  unless SystemLog.exists?
    SystemLog.create!(task_name: "FX Rate Update",       module_name: "Finance",     severity: :success, duration_seconds: 1.2)
    SystemLog.create!(task_name: "Shopify Price Sync",    module_name: "Marketplace", severity: :error,   duration_seconds: 5.4, error_message: "Auth Exception: Connection timeout after 5000ms")
    SystemLog.create!(task_name: "Inventory Audit",       module_name: "Warehouse",   severity: :warning, duration_seconds: 12.8, error_message: "Partial sync: 3 items skipped")
    SystemLog.create!(task_name: "Daily Backup",          module_name: "Core",        severity: :success, duration_seconds: 45.0)
    SystemLog.create!(task_name: "User Session Clean-up", module_name: "Auth",        severity: :success, duration_seconds: 0.8)
  end

  # --- Asset Fundamentals (sample AAPL OVERVIEW) ---
  if (aapl = Asset.find_by(symbol: "AAPL"))
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
  end

  # --- Fear & Greed Readings ---
  unless FearGreedReading.exists?
    FearGreedReading.create!(index_type: "crypto", value: 25, classification: "Fear", source: "alternative.me", fetched_at: 6.hours.ago)
    FearGreedReading.create!(index_type: "stocks", value: 62, classification: "Greed", source: "cnn", fetched_at: 6.hours.ago)
  end
end

puts "Seeded: #{User.count} users, #{Asset.count} assets, #{Position.count} positions, #{Trade.count} trades, #{AlertRule.count} alert rules, #{EarningsEvent.count} earnings, #{NewsArticle.count} news, #{Notification.count} notifications, #{PortfolioSnapshot.count} snapshots, #{FxRate.count} FX rates, #{Dividend.count} dividends."
