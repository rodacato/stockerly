namespace :data do
  desc "Backfill price history for assets with insufficient records"
  task backfill_prices: :environment do
    assets = Asset.where(sync_status: :active)
                  .left_joins(:asset_price_histories)
                  .group("assets.id")
                  .having("COUNT(asset_price_histories.id) < ?", BackfillMissingHistoriesJob::MIN_HISTORIES)

    count = assets.count.size
    puts "Backfilling price history for #{count} assets..."

    assets.each_with_index do |asset, index|
      BackfillPriceHistoryJob.set(wait: index * 5.seconds).perform_later(asset.id)
    end

    puts "Enqueued #{count} backfill jobs (5s spacing)"
  end

  desc "Backfill earnings calendar immediately"
  task backfill_earnings: :environment do
    puts "Syncing earnings calendar..."
    SyncEarningsJob.perform_later
    puts "Enqueued SyncEarningsJob"
  end

  desc "Backfill fundamentals for assets without fundamental data"
  task backfill_fundamentals: :environment do
    assets = Asset.where(sync_status: :active, asset_type: [ :stock, :etf ])
                  .where(fundamentals_synced_at: nil)

    count = assets.count
    puts "Backfilling fundamentals for #{count} assets..."

    assets.each_with_index do |asset, index|
      SyncFundamentalJob.set(wait: index * 15.seconds).perform_later(asset.id)
    end

    puts "Enqueued #{count} fundamental jobs (15s spacing)"
  end

  desc "Run all backfill tasks (prices, earnings, fundamentals)"
  task backfill_all: :environment do
    Rake::Task["data:backfill_prices"].invoke
    Rake::Task["data:backfill_earnings"].invoke
    Rake::Task["data:backfill_fundamentals"].invoke
  end
end

namespace :data do
  desc "Seed FxRateHistory with Banxico's full settlement FIX series (#318)"
  task backfill_fx_history: :environment do
    from = MarketData::Gateways::BanxicoGateway::FIX_SERIES_START
    before = FxRateHistory.count

    puts "Fetching the USD/MXN FIX from #{from} — one ranged request."

    case MarketData::UseCases::SyncFxHistory.call(from: from, to: Date.current)
    in Dry::Monads::Success(stored:, **)
      puts "Upserted #{stored} row(s); FxRateHistory went from #{before} to #{FxRateHistory.count}."
    in Dry::Monads::Failure[ _, message ]
      abort "Backfill failed: #{message}"
    end
  end
end

namespace :data do
  desc "Seed CetesRateHistory with every term's auction series — data:backfill_cetes_history[1980-01-01]"
  task :backfill_cetes_history, [ :from ] => :environment do |_task, args|
    gateway = MarketData::Gateways::BanxicoGateway
    from = args[:from] ? Date.parse(args[:from]) : gateway::CETES_HISTORY_FLOOR

    puts "Fetching every CETES term from #{from} — one ranged request each."

    gateway.cetes_terms.each do |term|
      case MarketData::UseCases::SyncCetesHistory.call(term: term, from: from, to: Date.current)
      in Dry::Monads::Success(stored:, **)
        scope = CetesRateHistory.where(term: term)
        puts format("  %-5s %5d stored · now %5d rows, %s..%s",
                    term, stored, scope.count, scope.minimum(:auction_date), scope.maximum(:auction_date))
      in Dry::Monads::Failure[ _, message ]
        puts format("  %-5s failed: %s", term, message)
      end
    end
  end
end
