# CoinGecko returns every coin's market data in one call, so crypto fundamentals
# are one job for the whole set rather than SyncFundamentalJob's one-asset-one-call
# shape, whose daily budget belongs to Alpha Vantage and would starve on them.
class SyncCryptoFundamentalsJob < ApplicationJob
  include PausableSync
  include SyncLogging

  TASK = "Crypto Fundamentals".freeze
  TRANSIENT = %i[rate_limited circuit_open].freeze

  queue_as :default

  def perform
    assets = Asset.where(asset_type: :crypto, sync_status: :active).index_by(&:symbol)
    return if assets.empty?

    result = breaker.call { MarketData::Gateways::CoingeckoGateway.new.fetch_market_data(assets.keys) }

    unless result.success?
      severity = TRANSIENT.include?(result.failure[0]) ? :warning : :error
      return log_sync_failure(TASK, result.failure[1], severity: severity)
    end

    stored = store(assets, result.value!)
    report(TASK, "#{stored.size} assets", unreachable: assets.keys - stored, total: assets.size)
  end

  private

  def breaker
    GatewayChain.breaker_for("crypto")
  end

  def store(assets_by_symbol, rows)
    rows.filter_map do |row|
      asset = assets_by_symbol[row[:symbol]]
      next unless asset

      MarketData::UseCases::StoreFundamentals.call(
        asset: asset,
        metrics: metrics_for(row),
        period_label: MarketData::UseCases::StoreFundamentals::CRYPTO
      )
      row[:symbol]
    end
  end

  # Translated once, here, so the stored row reads in the catalogue's own
  # vocabulary. The volume/market-cap ratio is derived by the presenter — nobody
  # serves it, and a stored copy would go stale against the two figures it needs.
  def metrics_for(row)
    {
      market_cap: row[:market_cap],
      circulating_supply: row[:circulating_supply],
      total_supply: row[:total_supply],
      fully_diluted_valuation: row[:fully_diluted_valuation],
      total_volume_24h: row[:total_volume],
      ath_price: row[:ath]
    }.compact.merge(data_source: MarketData::Gateways::CoingeckoGateway.name)
  end
end
