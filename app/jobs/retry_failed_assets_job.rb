# Nightly job that retries syncing assets stuck in sync_issue status.
# Auto-disables assets that have been in sync_issue for 7+ days.
class RetryFailedAssetsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  MAX_RETRIES_PER_RUN = 10
  AUTO_DISABLE_AFTER = 7.days

  def perform
    failed_assets = Asset.where(sync_status: :sync_issue).limit(MAX_RETRIES_PER_RUN)
    return if failed_assets.empty?

    failed_assets.each do |asset|
      if auto_disable?(asset)
        disable_asset(asset)
      else
        retry_asset(asset)
      end
    end
  end

  private

  def auto_disable?(asset)
    asset.sync_issue_since.present? && asset.sync_issue_since < AUTO_DISABLE_AFTER.ago
  end

  def disable_asset(asset)
    asset.update!(sync_status: :disabled)
    log_sync_failure(
      "Auto-disabled: #{asset.symbol}",
      "Asset in sync_issue for 7+ days (since #{asset.sync_issue_since.to_date})",
      severity: :warning
    )
  end

  def retry_asset(asset)
    result = gateway_for(asset).fetch_price(asset.symbol)

    if result.success?
      recover_asset(asset, result.value!)
    else
      log_sync_failure(
        "Retry Failed: #{asset.symbol}",
        result.failure[1],
        severity: :warning
      )
    end
  end

  def recover_asset(asset, data)
    asset.update!(
      sync_status: :active,
      sync_issue_since: nil,
      current_price: data[:price],
      change_percent_24h: data[:change_percent],
      price_updated_at: Time.current
    )

    log_sync_success("Retry Recovered: #{asset.symbol}")
  end

  def gateway_for(asset)
    case asset.asset_type
    when "stock", "index", "etf"
      GatewayChain.new(
        gateways: [ MarketData::PolygonGateway.new, MarketData::YahooFinanceGateway.new ]
      )
    when "crypto"
      GatewayChain.new(gateways: [ MarketData::CoingeckoGateway.new ])
    else
      GatewayChain.new(gateways: [ MarketData::YahooFinanceGateway.new ])
    end
  end
end
