# Fetches 30 days of historical OHLCV data for a single asset and
# upserts into AssetPriceHistory. Triggered by AssetCreated event.
class BackfillPriceHistoryJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?

    result = fetch_history(asset)

    if result.success?
      upsert_bars(asset, result.value!)
      log_sync_success("Backfill: #{asset.symbol}")
    else
      log_sync_failure("Backfill: #{asset.symbol}", result.failure[1])
    end
  end

  private

  def fetch_history(asset)
    case asset.asset_type
    when "crypto"
      MarketData::CoingeckoGateway.new.fetch_historical(asset.symbol, days: 30)
    when "stock", "index", "etf"
      fetch_stock_history(asset.symbol)
    else
      Dry::Monads::Failure([ :not_supported, "Backfill not supported for #{asset.asset_type}" ])
    end
  end

  def fetch_stock_history(symbol)
    from_date = 30.days.ago.to_date.to_s
    to_date   = Date.current.to_s
    result = MarketData::PolygonGateway.new.fetch_historical(symbol, from_date, to_date)
    return result if result.success?

    # Fallback to Yahoo Finance when Polygon fails (e.g. no API key)
    MarketData::YahooFinanceGateway.new.fetch_historical(symbol, days: 30)
  end

  def upsert_bars(asset, bars)
    bars.each do |bar|
      AssetPriceHistory.find_or_initialize_by(asset_id: asset.id, date: bar[:date]).tap do |record|
        record.assign_attributes(
          open: bar[:open],
          high: bar[:high],
          low: bar[:low],
          close: bar[:close],
          volume: bar[:volume]
        )
        record.save!
      end
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    # Ignore race conditions on concurrent upserts
  end
end
