# Fetches DAYS of historical OHLCV data for a single asset. Triggered by
# AssetCreated. The fetching and writing live in MarketData::UseCases::
# SyncPriceHistory, which `data:deepen` calls over a longer range.
class BackfillPriceHistoryJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  DAYS = 365

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?

    case MarketData::UseCases::SyncPriceHistory.call(asset: asset, from: DAYS.days.ago.to_date)
    in Dry::Monads::Success(written:, rejected:, **)
      log_backfill(asset, stored: written, rejected: rejected)
    in Dry::Monads::Failure[ _kind, message ]
      log_sync_failure("Backfill: #{asset.symbol}", message)
    end
  end

  private

  def log_backfill(asset, stored:, rejected:)
    return log_sync_success("Backfill: #{asset.symbol}", message: "#{stored} bars") if rejected.zero?

    log_sync_failure("Backfill: #{asset.symbol}",
                     "#{stored} bars stored, #{rejected} rejected",
                     severity: :warning)
  end
end
