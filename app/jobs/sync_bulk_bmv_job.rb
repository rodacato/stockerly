# Fetches prices for multiple BMV (Mexican) assets in a single DataBursatil
# call, updates each Asset record, and publishes MarketData::Events::AssetPriceUpdated
# events. DataBursatil is the sanctioned source; Yahoo answers 429 to everything
# we can send it, so it is no longer a dependency here.
class SyncBulkBmvJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  # The one failure a reader can act on: the provider does not know this name.
  UNNAMED = "sin_fuente".freeze

  def perform(asset_ids)
    provider = MarketData::Gateways::DataBursatilGateway::PROVIDER
    assets = Asset.where(id: asset_ids, sync_status: :active).index_by { |asset| asset.symbol_for(provider) }
    return if assets.empty?

    result = breaker.call { MarketData::Gateways::DataBursatilGateway.new.fetch_bulk_prices(assets.keys) }

    if result.success?
      update_assets(assets, result.value!)
      report(assets, result.value!)
    elsif result.failure[0] == :rate_limited || result.failure[0] == :circuit_open
      log_sync_failure("Bulk BMV Sync", result.failure[1], severity: :warning)
    else
      log_sync_failure("Bulk BMV Sync", result.failure[1])
    end
  end

  private

  # A name DataBursatil does not recognise is simply absent from the response —
  # measured 2026-08-27, a mixed batch answers 200 with the rest. So a partial
  # answer used to log "N assets" and leave the missing one stale with nothing
  # said, which is the quietest way to be wrong.
  def report(assets, quotes)
    missing = assets.keys - quotes.map { |quote| quote[:symbol] }

    if missing.empty?
      log_sync_success("Bulk BMV Sync: #{quotes.size} assets")
      return
    end

    # The log says it once for the run; the asset carries it so its own row can
    # say it too, and so the reader learns which one is stale from the screen
    # they were already on.
    Asset.where(id: missing.map { |symbol| assets[symbol].id })
         .update_all(last_sync_error: UNNAMED, last_synced_at: Time.current)

    log_sync_failure(
      "Bulk BMV Sync",
      "Priced #{quotes.size} of #{assets.size}. No quote for: #{missing.join(', ')} — " \
      "the serie is probably missing. Run `rake data:resolve_bmv_symbols`.",
      severity: :warning
    )
  end

  def breaker
    GatewayChain.breaker_for("databursatil")
  end

  def update_assets(assets_by_symbol, results)
    results.each do |data|
      asset = assets_by_symbol[data[:symbol]]
      next unless asset

      old_price = asset.current_price

      asset.update!(
        current_price: data[:price],
        volume: data[:volume] || asset.volume,
        price_updated_at: Time.current,
        last_sync_error: nil
      )

      next unless price_changed?(old_price, data[:price])

      EventBus.publish(MarketData::Events::AssetPriceUpdated.new(
        asset_id: asset.id,
        symbol: asset.symbol,
        old_price: (old_price || 0).to_s,
        new_price: data[:price].to_s,
        source: data[:source] || MarketData::Gateways::DataBursatilGateway.source_id
      ))
    end
  end

  def price_changed?(old_price, new_price)
    old_price.nil? || old_price.to_d != new_price.to_d
  end
end
