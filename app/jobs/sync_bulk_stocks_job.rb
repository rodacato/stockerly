# Fetches prices for multiple US stock assets using Polygon's grouped daily endpoint,
# updates each Asset record, and publishes AssetPriceUpdated events.
# Similar pattern to SyncBulkCryptoJob but uses Polygon's grouped endpoint
# for a single API call covering all US stocks.
class SyncBulkStocksJob < ApplicationJob
  include SyncLogging

  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  def perform(asset_ids)
    assets = Asset.where(id: asset_ids, sync_status: :active).index_by(&:symbol)
    return if assets.empty?

    result = breaker.call { PolygonGateway.new.fetch_grouped_daily }

    if result.success?
      updated = update_assets(assets, result.value!)
      log_sync_success("Bulk Stock Sync", message: "#{updated}/#{assets.size} updated")
    elsif result.failure[0] == :rate_limited || result.failure[0] == :circuit_open
      log_sync_failure("Bulk Stock Sync", result.failure[1], severity: :warning)
    else
      log_sync_failure("Bulk Stock Sync", result.failure[1])
    end
  end

  private

  def breaker
    SyncSingleAssetJob.circuit_breaker_for("stock")
  end

  def update_assets(assets_by_symbol, results)
    updated = 0

    results.each do |data|
      asset = assets_by_symbol[data[:symbol]]
      next unless asset

      old_price = asset.current_price

      asset.update!(
        current_price: data[:price],
        change_percent_24h: data[:change_percent],
        volume: data[:volume] || asset.volume,
        price_updated_at: Time.current
      )

      updated += 1

      next unless price_changed?(old_price, data[:price])

      EventBus.publish(AssetPriceUpdated.new(
        asset_id: asset.id,
        symbol: asset.symbol,
        old_price: (old_price || 0).to_s,
        new_price: data[:price].to_s
      ))
    end

    updated
  end

  def price_changed?(old_price, new_price)
    old_price.nil? || old_price.to_d != new_price.to_d
  end
end
