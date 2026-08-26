# Enqueues SyncSingleAssetJob for each active asset of the given type.
# Spaces out individual jobs to respect API rate limits.
class SyncAllAssetsJob < ApplicationJob
  include PausableSync
  queue_as :default

  # @param asset_type [String] "stock" or "crypto"
  def perform(asset_type = nil)
    scope = Asset.syncing
    scope = scope.where(asset_type: asset_type) if asset_type.present?

    scope.find_each.with_index do |asset, index|
      SyncSingleAssetJob.set(wait: index * spacing_seconds(asset)).perform_later(asset.id)
    end
  end

  private

  # Spaced for the slowest free tier in the chain
  # Yahoo Finance: generous limits → 2s spacing
  # CoinGecko: bulk endpoint used in SyncSingleAssetJob, so less critical
  def spacing_seconds(asset)
    return 2 if asset.country == "MX"

    case asset.asset_type
    when "stock", "etf" then 12
    when "crypto"       then 2
    else 5
    end
  end
end
