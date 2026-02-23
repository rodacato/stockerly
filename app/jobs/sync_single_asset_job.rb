# Fetches the latest price for a single asset from the appropriate gateway,
# updates the Asset record, and publishes AssetPriceUpdated if the price changed.
class SyncSingleAssetJob < ApplicationJob
  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?
    return if recently_synced?(asset)

    result = fetch_price(asset)

    if result.success?
      update_asset(asset, result.value!)
      log_success(asset)
    elsif result.failure[0] == :rate_limited
      log_failure(asset, result.failure[1], severity: :warning)
    elsif result.failure[0] == :circuit_open
      log_failure(asset, result.failure[1], severity: :warning)
    else
      log_failure(asset, result.failure[1])
    end
  end

  private

  def recently_synced?(asset)
    return false if asset.price_updated_at.nil?

    min_interval = asset.asset_type_crypto? ? 2.minutes : 4.minutes
    asset.price_updated_at > min_interval.ago
  end

  def fetch_price(asset)
    breaker = self.class.circuit_breaker_for(breaker_key(asset))
    breaker.call { gateway_for(asset).fetch_price(asset.symbol) }
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
    return YahooFinanceGateway.new if asset.country == "MX"

    case asset.asset_type
    when "stock", "index", "etf" then PolygonGateway.new
    when "crypto"                then CoingeckoGateway.new
    else
      raise ArgumentError, "Unknown asset type: #{asset.asset_type}"
    end
  end

  def breaker_key(asset)
    return "bmv" if asset.country == "MX"

    asset.asset_type
  end

  def update_asset(asset, data)
    old_price = asset.current_price

    asset.update!(
      current_price: data[:price],
      change_percent_24h: data[:change_percent],
      volume: data[:volume] || asset.volume,
      market_cap: data[:market_cap] || asset.market_cap,
      price_updated_at: Time.current
    )

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

  def log_success(asset)
    SystemLog.create!(
      task_name: "Price Sync: #{asset.symbol}",
      module_name: "sync",
      severity: :success,
      duration_seconds: 0
    )
  end

  def log_failure(asset, message, severity: :error)
    SystemLog.create!(
      task_name: "Price Sync: #{asset.symbol}",
      module_name: "sync",
      severity: severity,
      error_message: message
    )
  end
end
