# Fetches the latest price for a single asset from the appropriate gateway
# (with fallback chain for US stocks), updates the Asset record, and
# publishes AssetPriceUpdated if the price changed.
class SyncSingleAssetJob < ApplicationJob
  include SyncLogging

  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?
    return if recently_synced?(asset)

    result = gateway_for(asset).fetch_price(asset.symbol)

    if result.success?
      update_asset(asset, result.value!)
      log_sync_success("Price Sync: #{asset.symbol}")
    elsif result.failure[0] == :rate_limited
      log_sync_failure("Price Sync: #{asset.symbol}", result.failure[1], severity: :warning)
    elsif result.failure[0] == :circuit_open
      log_sync_failure("Price Sync: #{asset.symbol}", result.failure[1], severity: :warning)
    elsif result.failure[0] == :all_gateways_failed
      publish_all_gateways_failed(asset, result.failure[2])
      log_sync_failure("Price Sync: #{asset.symbol}", result.failure[1])
    else
      log_sync_failure("Price Sync: #{asset.symbol}", result.failure[1])
    end
  end

  private

  def recently_synced?(asset)
    return false if asset.price_updated_at.nil?

    min_interval = asset.asset_type_crypto? ? 2.minutes : 4.minutes
    asset.price_updated_at > min_interval.ago
  end

  CIRCUIT_BREAKERS = {}

  def self.circuit_breaker_for(key)
    CIRCUIT_BREAKERS[key] ||= CircuitBreaker.new(
      name: "#{key}_gateway",
      threshold: 5,
      timeout: 60
    )
  end

  def gateway_for(asset)
    return GatewayChain.new(gateways: [YahooFinanceGateway.new]) if asset.country == "MX"

    case asset.asset_type
    when "stock", "index", "etf"
      GatewayChain.new(
        gateways: [PolygonGateway.new, YahooFinanceGateway.new],
        circuit_breakers: {
          "PolygonGateway" => self.class.circuit_breaker_for("stock"),
          "YahooFinanceGateway" => self.class.circuit_breaker_for("yahoo_us")
        }
      )
    when "crypto"
      GatewayChain.new(gateways: [CoingeckoGateway.new])
    else
      raise ArgumentError, "Unknown asset type: #{asset.asset_type}"
    end
  end

  def update_asset(asset, data)
    old_price = asset.current_price

    update_attrs = {
      current_price: data[:price],
      change_percent_24h: data[:change_percent],
      volume: data[:volume] || asset.volume,
      market_cap: data[:market_cap] || asset.market_cap,
      price_updated_at: Time.current
    }
    update_attrs[:data_source] = data[:data_source] if data[:data_source]

    asset.update!(update_attrs)

    publish_price_update(asset, old_price, data[:price]) if price_changed?(old_price, data[:price])
  end

  def price_changed?(old_price, new_price)
    old_price.nil? || old_price.to_d != new_price.to_d
  end

  def publish_price_update(asset, old_price, new_price)
    EventBus.publish(AssetPriceUpdated.new(
      asset_id: asset.id,
      symbol: asset.symbol,
      old_price: (old_price || 0).to_s,
      new_price: new_price.to_s
    ))
  end

  def publish_all_gateways_failed(asset, attempted)
    EventBus.publish(AllGatewaysFailed.new(
      asset_id: asset.id,
      symbol: asset.symbol,
      attempted_gateways: Array(attempted)
    ))
  end
end
