namespace :data do
  desc "Sync all asset prices and history from live APIs (Yahoo Finance + CoinGecko)"
  task sync: :environment do
    puts "=== Stockerly Data Sync ==="
    puts ""

    # Step 1: Clear broken Clearbit logos
    cleared = Asset.where("logo_url LIKE ?", "%clearbit%").update_all(logo_url: nil)
    puts "Cleared #{cleared} broken Clearbit logo URLs" if cleared > 0

    # Step 2: Sync crypto prices via CoinGecko
    puts "\n--- Crypto Prices (CoinGecko) ---"
    cg = CoingeckoGateway.new(api_key: "")
    crypto_assets = Asset.where(asset_type: :crypto)
    crypto_symbols = crypto_assets.pluck(:symbol)

    if crypto_symbols.any?
      result = cg.fetch_bulk_prices(crypto_symbols)
      if result.success?
        result.value!.each do |data|
          asset = crypto_assets.find_by(symbol: data[:symbol])
          next unless asset
          asset.update!(
            current_price: data[:price],
            change_percent_24h: data[:change_percent],
            market_cap: data[:market_cap] || asset.market_cap,
            price_updated_at: Time.current
          )
          puts "  #{data[:symbol]}: $#{data[:price]} (#{data[:change_percent]}%)"
        end
      else
        puts "  FAILED: #{result.failure.inspect}"
      end
    end

    # Step 3: Sync stock/ETF prices via Yahoo Finance
    puts "\n--- Stock & ETF Prices (Yahoo Finance) ---"
    yf = YahooFinanceGateway.new
    stock_etf_assets = Asset.where(asset_type: [ :stock, :etf ]).where.not(symbol: [ "CETE28D", "CETE364D" ])

    stock_etf_assets.find_each do |asset|
      result = yf.fetch_price(asset.symbol)
      if result.success?
        data = result.value!
        asset.update!(
          current_price: data[:price],
          change_percent_24h: data[:change_percent],
          volume: data[:volume] || asset.volume,
          price_updated_at: Time.current
        )
        puts "  #{asset.symbol}: $#{data[:price]} (#{data[:change_percent]}%)"
      else
        puts "  #{asset.symbol}: FAILED - #{result.failure[1]}"
      end
      sleep 0.5 # Rate limit courtesy
    end

    # Step 4: Sync market indices via Yahoo Finance
    puts "\n--- Market Indices (Yahoo Finance) ---"
    result = yf.fetch_index_quotes
    if result.success?
      result.value!.each do |data|
        index = MarketIndex.find_by(symbol: data[:symbol])
        next unless index
        index.update!(
          value: data[:value],
          change_percent: data[:change_percent],
          is_open: data[:is_open]
        )
        puts "  #{data[:symbol]}: #{data[:value]} (#{data[:change_percent]}%)"
      end
    else
      puts "  FAILED: #{result.failure.inspect}"
    end

    # Step 5: Backfill price history for sparklines
    puts "\n--- Price History (30 days) ---"
    # Crypto history from CoinGecko
    crypto_assets.find_each do |asset|
      result = cg.fetch_historical(asset.symbol, days: 30)
      if result.success?
        upsert_bars(asset, result.value!)
        puts "  #{asset.symbol}: #{result.value!.size} bars"
      else
        puts "  #{asset.symbol}: FAILED - #{result.failure[1]}"
      end
      sleep 1
    end

    # Stock/ETF history from Yahoo Finance
    stock_etf_assets.find_each do |asset|
      result = yf.fetch_historical(asset.symbol, days: 30)
      if result.success?
        upsert_bars(asset, result.value!)
        puts "  #{asset.symbol}: #{result.value!.size} bars"
      else
        puts "  #{asset.symbol}: FAILED - #{result.failure[1]}"
      end
      sleep 0.5
    end

    puts "\n=== Sync Complete ==="
    puts "Assets with prices: #{Asset.where.not(current_price: nil).count}/#{Asset.count}"
    puts "Price history records: #{AssetPriceHistory.count}"
  end

  private

  def upsert_bars(asset, bars)
    bars.each do |bar|
      AssetPriceHistory.find_or_initialize_by(asset_id: asset.id, date: bar[:date]).tap do |record|
        record.assign_attributes(
          open: bar[:open], high: bar[:high], low: bar[:low],
          close: bar[:close], volume: bar[:volume]
        )
        record.save!
      end
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # Ignore race conditions
  end
end
