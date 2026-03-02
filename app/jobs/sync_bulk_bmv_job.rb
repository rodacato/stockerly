# Fetches prices for multiple BMV (Mexican) assets in a single Yahoo Finance
# API call, updates each Asset record, and publishes MarketData::AssetPriceUpdated events.
class SyncBulkBmvJob < ApplicationJob
  include SyncLogging

  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  def perform(asset_ids)
    assets = Asset.where(id: asset_ids, sync_status: :active).index_by(&:symbol)
    return if assets.empty?

    result = breaker.call { MarketData::YahooFinanceGateway.new.fetch_bulk_prices(assets.keys) }

    if result.success?
      update_assets(assets, result.value!)
      log_sync_success("Bulk BMV Sync: #{assets.size} assets")
    elsif result.failure[0] == :rate_limited || result.failure[0] == :circuit_open
      log_sync_failure("Bulk BMV Sync", result.failure[1], severity: :warning)
    else
      log_sync_failure("Bulk BMV Sync", result.failure[1])
    end
  end

  private

  def breaker
    SyncSingleAssetJob.circuit_breaker_for("bmv")
  end

  def update_assets(assets_by_symbol, results)
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

      next unless price_changed?(old_price, data[:price])

      EventBus.publish(MarketData::AssetPriceUpdated.new(
        asset_id: asset.id,
        symbol: asset.symbol,
        old_price: (old_price || 0).to_s,
        new_price: data[:price].to_s
      ))
    end
  end

  def price_changed?(old_price, new_price)
    old_price.nil? || old_price.to_d != new_price.to_d
  end
end
