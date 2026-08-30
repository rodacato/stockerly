# Syncs fundamental data for a single asset through the registry's chain.
# 1 job = 1 API call (atomic, resilient). Triggered by SyncAllFundamentalsJob.
class SyncFundamentalJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?
    # Crypto is not excluded, it is served elsewhere: SyncCryptoFundamentalsJob
    # fetches every coin in one CoinGecko call, off this job's Alpha Vantage budget.
    return unless asset.asset_type_stock? || asset.asset_type_etf?

    result = fundamentals_chain.fetch_overview(asset.symbol)

    if result.success?
      store(asset, result.value!)
    else
      log_sync_failure("Fundamentals: #{asset.symbol}", result.failure[1],
        severity: result.failure[0] == :rate_limited ? :warning : :error)
    end
  end

  private

  def store(asset, data)
    MarketData::UseCases::StoreFundamentals.call(asset: asset, metrics: data)
    log_sync_success("Fundamentals: #{asset.symbol}")
  end

  # FMP was the fallback here, and its /api/v3 is gated the same way its
  # dividend routes are — a fallback that 403s for every new key is worse than
  # none, because it spends a call to hide the real state (#312).
  def fundamentals_chain
    GatewayChain.for_capability(:fundamentals)
  end
end
