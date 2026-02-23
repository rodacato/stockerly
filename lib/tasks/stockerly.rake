namespace :stockerly do
  desc "Idempotent asset seeding — safe for production (find_or_create_by symbol)"
  task seed_assets: :environment do
    assets = [
      # US Tech (NASDAQ)
      { symbol: "AAPL",  name: "Apple Inc.",        asset_type: :stock, sector: "Technology",       exchange: "NASDAQ", country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/apple.com" },
      { symbol: "MSFT",  name: "Microsoft Corp.",   asset_type: :stock, sector: "Technology",       exchange: "NASDAQ", country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/microsoft.com" },
      { symbol: "NVDA",  name: "NVIDIA Corp.",      asset_type: :stock, sector: "Technology",       exchange: "NASDAQ", country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/nvidia.com" },
      { symbol: "GOOGL", name: "Alphabet Inc.",     asset_type: :stock, sector: "Technology",       exchange: "NASDAQ", country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/google.com" },
      { symbol: "META",  name: "Meta Platforms",    asset_type: :stock, sector: "Technology",       exchange: "NASDAQ", country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/meta.com" },
      { symbol: "AMZN",  name: "Amazon.com Inc.",   asset_type: :stock, sector: "Consumer Cyclical", exchange: "NASDAQ", country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/amazon.com" },
      # US Other (NYSE / NASDAQ)
      { symbol: "TSLA",  name: "Tesla, Inc.",       asset_type: :stock, sector: "Consumer Cyclical", exchange: "NASDAQ", country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/tesla.com" },
      { symbol: "JPM",   name: "JPMorgan Chase",   asset_type: :stock, sector: "Finance",          exchange: "NYSE",   country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/jpmorganchase.com" },
      { symbol: "JNJ",   name: "Johnson & Johnson", asset_type: :stock, sector: "Healthcare",       exchange: "NYSE",   country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/jnj.com" },
      { symbol: "OKE",   name: "Oneok Inc.",        asset_type: :stock, sector: "Energy",           exchange: "NYSE",   country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/oneok.com" },
      { symbol: "KO",    name: "Coca-Cola Co.",     asset_type: :stock, sector: "Consumer",         exchange: "NYSE",   country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/coca-cola.com" },
      { symbol: "PG",    name: "Procter & Gamble",  asset_type: :stock, sector: "Consumer",         exchange: "NYSE",   country: "US", data_source: "Polygon.io",  logo_url: "https://logo.clearbit.com/pg.com" },
      # US ETFs
      { symbol: "QQQ",   name: "Invesco QQQ Trust",    asset_type: :etf, exchange: "NASDAQ", country: "US", data_source: "Polygon.io", logo_url: "https://logo.clearbit.com/invesco.com" },
      { symbol: "SPY",   name: "SPDR S&P 500 ETF",     asset_type: :etf, exchange: "NYSE",   country: "US", data_source: "Polygon.io", logo_url: "https://logo.clearbit.com/ssga.com" },
      { symbol: "VOO",   name: "Vanguard S&P 500",     asset_type: :etf, exchange: "NYSE",   country: "US", data_source: "Polygon.io", logo_url: "https://logo.clearbit.com/vanguard.com" },
      { symbol: "VTI",   name: "Vanguard Total Stock",  asset_type: :etf, exchange: "NYSE",   country: "US", data_source: "Polygon.io", logo_url: "https://logo.clearbit.com/vanguard.com" },
      { symbol: "ARKK",  name: "ARK Innovation ETF",   asset_type: :etf, exchange: "NYSE",   country: "US", data_source: "Polygon.io", logo_url: "https://logo.clearbit.com/ark-invest.com" },
      # Crypto
      { symbol: "BTC",   name: "Bitcoin",    asset_type: :crypto, data_source: "CoinGecko API", logo_url: "https://assets.coingecko.com/coins/images/1/small/bitcoin.png" },
      { symbol: "ETH",   name: "Ethereum",   asset_type: :crypto, data_source: "CoinGecko API", logo_url: "https://assets.coingecko.com/coins/images/279/small/ethereum.png" },
      { symbol: "SOL",   name: "Solana",     asset_type: :crypto, data_source: "CoinGecko API", logo_url: "https://assets.coingecko.com/coins/images/4128/small/solana.png" },
      # Mexico (BMV) — prices via Yahoo Finance
      { symbol: "GENIUSSACV.MX", name: "Genius Sports SAB",   asset_type: :stock, sector: "Technology", exchange: "BMV", country: "MX", data_source: "Yahoo Finance" },
      { symbol: "IVVPESO.MX",    name: "iShares S&P 500 MXN", asset_type: :etf,                        exchange: "BMV", country: "MX", data_source: "Yahoo Finance" },
      # Indices
      { symbol: "VIX", name: "CBOE Volatility Index", asset_type: :index, exchange: "CBOE", country: "US" }
    ]

    created = 0
    updated = 0

    assets.each do |attrs|
      symbol = attrs[:symbol]
      asset = Asset.find_or_create_by!(symbol: symbol) do |a|
        attrs.except(:symbol).each { |k, v| a.send(:"#{k}=", v) }
        created += 1
      end

      # Backfill country and logo_url on existing assets that lack them
      backfill = {}
      backfill[:country]  = attrs[:country]  if attrs[:country].present?  && asset.country.blank?
      backfill[:logo_url] = attrs[:logo_url] if attrs[:logo_url].present? && asset.logo_url.blank?
      if backfill.any?
        asset.update!(backfill)
        updated += 1
      end
    end

    puts "Assets: #{created} created, #{updated} backfilled, #{Asset.count} total"
  end

  desc "Promote a user to admin by email"
  task :promote_admin, [ :email ] => :environment do |_t, args|
    email = args[:email]
    abort "Usage: rake stockerly:promote_admin[user@example.com]" if email.blank?

    user = User.find_by(email: email.downcase.strip)
    abort "User not found: #{email}" unless user

    if user.admin?
      puts "#{user.email} is already an admin."
    else
      user.update!(role: :admin)
      puts "Promoted #{user.email} to admin."
    end
  end
end
