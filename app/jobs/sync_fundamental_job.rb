# Syncs fundamental data for a single asset via Alpha Vantage OVERVIEW.
# 1 job = 1 API call (atomic, resilient). Triggered by SyncAllFundamentalsJob.
class SyncFundamentalJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?
    return unless asset.asset_type_stock? || asset.asset_type_etf?

    result = breaker.call { MarketData::Gateways::AlphaVantageGateway.new.fetch_overview(asset.symbol) }

    if result.success?
      persist(asset, result.value!)
    else
      log_sync_failure("Fundamentals: #{asset.symbol}", result.failure[1],
        severity: result.failure[0] == :rate_limited ? :warning : :error)
    end
  end

  private

  def persist(asset, data)
    fundamental = AssetFundamental.find_or_initialize_by(
      asset: asset, period_label: "OVERVIEW"
    )
    fundamental.update!(
      metrics: data,
      source: "api_overview",
      calculated_at: Time.current
    )

    asset.update!(fundamentals_synced_at: Time.current)

    log_sync_success("Fundamentals: #{asset.symbol}")

    EventBus.publish(MarketData::Events::AssetFundamentalsUpdated.new(
      asset_id: asset.id,
      symbol: asset.symbol,
      source: "alpha_vantage_overview"
    ))
  end

  def breaker
    SyncSingleAssetJob.circuit_breaker_for("alpha_vantage")
  end
end
