# One-off deepening of daily history, kept apart from BackfillPriceHistoryJob on
# purpose: that job is the routine 365-day path every new asset takes, and this
# one rewrites nothing. See ADR-0024 and docs/ops/prod-mirror.md.
module DeepenHistory
  # Yahoo is one call per symbol against 2,000 a day; Alpaca is 200 a minute
  # against 50,000 and returns bars already adjusted for splits and dividends.
  # Which is why this routes rather than naming a gateway: every asset deepens
  # from the source that already owns it, and its provenance does not move.
  PACING = 2.seconds

  module_function

  def call(asset, years)
    sources = DataSourceRegistry.for_capability(:historical, market: asset.market, asset_type: asset.asset_type)
    return puts(format("  %-12s no source serves %s/%s", asset.symbol, asset.market, asset.asset_type)) if sources.empty?

    bars, source = fetch(sources, asset, years)
    return puts(format("  %-12s every source refused", asset.symbol)) if bars.nil?

    report(asset, bars, source, insert_missing(asset, bars, source))
  end

  def fetch(sources, asset, years)
    from = years.years.ago.to_date

    sources.each do |source|
      klass = source.gateway_class
      symbol = klass.const_defined?(:PROVIDER) ? asset.symbol_for(klass::PROVIDER) : asset.symbol
      result = begin
        klass.new.fetch_historical(symbol, from, Date.current)
      rescue MarketData::Gateways::ApiKeyNotConfiguredError
        next
      end

      return [ result.value!, klass.source_id ] if result.success? && result.value!.present?
    end

    nil
  end

  # Existing rows keep the source that wrote them, so a deepening can add
  # history and can never restate it. Sources disagree in the third decimal.
  def insert_missing(asset, bars, source)
    known = asset.asset_price_histories.where(interval: "1d").pluck(:date).to_set
    fresh = bars.uniq { |bar| bar[:date] }.reject { |bar| known.include?(bar[:date]) }
    return 0 if fresh.empty?

    inserted = 0
    AssetPriceHistory.transaction do
      fresh.each do |bar|
        create_bar(asset, bar, source)
        inserted += 1
      rescue ActiveRecord::RecordInvalid
        next
      end
    end
    inserted
  end

  def create_bar(asset, bar, source)
    AssetPriceHistory.create!(
      asset_id: asset.id, date: bar[:date], interval: "1d",
      open: bar[:open], high: bar[:high], low: bar[:low], close: bar[:close], volume: bar[:volume],
      source: source, status: "confirmed", as_of: bar[:date].end_of_day, fetched_at: Time.current
    )
  end

  # The span is printed because the two failure modes worth catching are only
  # visible in it: a young listing returns little, a reused ticker returns a
  # history that starts before the company did.
  def report(asset, bars, source, inserted)
    scope = asset.asset_price_histories.where(interval: "1d")
    puts format("  %-12s %-22s %5d fetched %s..%s · %5d new · now %s..%s (%d rows)",
                asset.symbol, source, bars.size, bars.first[:date], bars.last[:date],
                inserted, scope.minimum(:date), scope.maximum(:date), scope.count)
  end
end

namespace :data do
  # `years` is a floor, not a window. Yahoo's gateway can only express
  # 5d/1mo/3mo/1y/2y/max, so anything past two years fetches everything it has.
  desc "Deepen one symbol's daily history — data:deepen[NVDA,5]"
  task :deepen, [ :symbol, :years ] => :environment do |_task, args|
    abort "Usage: bin/rails 'data:deepen[SYMBOL,YEARS]'" if args[:symbol].blank?

    asset = Asset.find_by(symbol: args[:symbol].upcase)
    abort "No asset with symbol #{args[:symbol]}" if asset.nil?

    years = (args[:years] || 10).to_i
    puts "Deepening #{asset.symbol} to #{years} years"
    DeepenHistory.call(asset, years)
  end

  desc "Deepen every active asset, paced — data:deepen_all[10]"
  task :deepen_all, [ :years ] => :environment do |_task, args|
    years = (args[:years] || 10).to_i
    assets = Asset.where(sync_status: :active).order(:symbol)

    puts "Deepening #{assets.count} assets to #{years} years"
    assets.find_each.with_index do |asset, index|
      sleep(DeepenHistory::PACING) unless index.zero?
      DeepenHistory.call(asset, years)
    end
  end
end
