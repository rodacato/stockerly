# One-off deepening of daily history. The fetching and writing are
# MarketData::UseCases::SyncPriceHistory, the same action the routine backfill
# job runs — this only chooses the range and never rewrites. See ADR-0024.
module DeepenHistory
  YEARS = 10
  PACING = 2.seconds

  module_function

  def call(asset, years)
    result = MarketData::UseCases::SyncPriceHistory.call(
      asset: asset, from: years.years.ago.to_date, overwrite: false
    )

    case result
    in Dry::Monads::Success(source:, fetched:, written:, **)
      report(asset, source, fetched, written)
    in Dry::Monads::Failure[ _kind, message ]
      puts format("  %-12s %s", asset.symbol, message)
    end
  end

  # The span is printed because the two failure modes worth catching are only
  # visible in it: a young listing returns little, a reused ticker returns a
  # history that starts before the company did.
  def report(asset, source, fetched, written)
    scope = asset.asset_price_histories.where(interval: "1d")
    puts format("  %-12s %-22s %5d fetched · %5d new · now %s..%s (%d rows)",
                asset.symbol, source, fetched, written,
                scope.minimum(:date), scope.maximum(:date), scope.count)
  end
end

namespace :data do
  # `years` is a floor, not a window: Yahoo's gateway can only express
  # 5d/1mo/3mo/1y/2y/max, so past two years it returns everything it has.
  desc "Deepen one symbol's daily history — data:deepen[NVDA,10]"
  task :deepen, [ :symbol, :years ] => :environment do |_task, args|
    abort "Usage: bin/rails 'data:deepen[SYMBOL,YEARS]'" if args[:symbol].blank?

    asset = Asset.find_by(symbol: args[:symbol].upcase)
    abort "No asset with symbol #{args[:symbol]}" if asset.nil?

    years = (args[:years] || DeepenHistory::YEARS).to_i
    puts "Deepening #{asset.symbol} to #{years} years"
    DeepenHistory.call(asset, years)
  end

  desc "Deepen every active asset, paced — data:deepen_all[10]"
  task :deepen_all, [ :years ] => :environment do |_task, args|
    years = (args[:years] || DeepenHistory::YEARS).to_i
    assets = Asset.where(sync_status: :active).order(:symbol)

    puts "Deepening #{assets.count} assets to #{years} years"
    assets.find_each.with_index do |asset, index|
      sleep(DeepenHistory::PACING) unless index.zero?
      DeepenHistory.call(asset, years)
    end
  end
end
