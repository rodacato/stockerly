# Orchestrates price syncing based on asset priority and market hours.
# Replaces SyncAllAssetsJob in the recurring schedule for smarter
# API usage: high-priority assets sync more frequently, low-priority
# less often, and nothing syncs when the market is closed.
class SyncPriorityAssetsJob < ApplicationJob
  queue_as :default

  # @param asset_type [String] "stock", "crypto", "etf", or "index"
  # @param priority [String] "high", "low", or "all"
  def perform(asset_type, priority)
    scope = Asset.syncing.where(asset_type: asset_type)

    unless priority == "all"
      scope = priority == "high" ? scope.high_priority : scope.low_priority
    end

    if asset_type == "crypto"
      sync_crypto(scope)
    else
      sync_equities(scope)
    end
  end

  private

  def sync_crypto(scope)
    ids = scope.pluck(:id)
    SyncBulkCryptoJob.perform_later(ids) if ids.any?
  end

  def sync_equities(scope)
    bmv_assets = scope.where(country: "MX")
    us_assets  = scope.where(country: [ nil, "" ]).or(scope.where.not(country: "MX"))

    if bmv_assets.exists? && MarketHours.bmv_market_open?
      SyncBulkBmvJob.perform_later(bmv_assets.pluck(:id))
    end

    return unless us_assets.exists? && MarketHours.us_market_open?

    us_assets.find_each.with_index do |asset, index|
      SyncSingleAssetJob.set(wait: index * 12).perform_later(asset.id)
    end
  end
end
