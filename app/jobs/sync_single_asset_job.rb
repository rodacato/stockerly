# Fetches the latest price for a single asset from the appropriate gateway
# (with fallback chain for US stocks), updates the Asset record, and
# publishes MarketData::Events::AssetPriceUpdated if the price changed.
class SyncSingleAssetJob < ApplicationJob
  include PausableSync
  include SyncLogging
  include AdaptiveScheduling

  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  def perform(asset_id)
    asset = Asset.find_by(id: asset_id)
    return unless asset&.active?
    return if recently_synced?(asset)

    result = gateway_for(asset).fetch_price(asset.gateway_symbols)

    if result.success?
      update_asset(asset, result.value!)
      log_sync_success("Price Sync: #{asset.symbol}")
      adaptive_reset(asset.asset_type)
    elsif result.failure[0] == :rate_limited
      adaptive_backoff(asset.asset_type)
      log_sync_failure("Price Sync: #{asset.symbol}", result.failure[1], severity: :warning)
    elsif result.failure[0] == :circuit_open
      log_sync_failure("Price Sync: #{asset.symbol}", result.failure[1], severity: :warning)
    elsif result.failure[0] == :all_gateways_failed
      publish_all_gateways_failed(asset, result.failure[2])
      record_sync_failure(asset, result.failure[1])
      log_sync_failure("Price Sync: #{asset.symbol}", result.failure[1])
    else
      record_sync_failure(asset, result.failure[1])
      log_sync_failure("Price Sync: #{asset.symbol}", result.failure[1])
    end
  end

  private

  # Records the failed attempt on the asset; never pauses it (user's call).
  def record_sync_failure(asset, message)
    asset.update_columns(last_synced_at: Time.current, last_sync_error: message)
  end

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
    if asset.country == "MX"
      return build_chain(
        [ MarketData::Gateways::DataBursatilGateway, MarketData::Gateways::YahooFinanceGateway ],
        { "MarketData::Gateways::DataBursatilGateway" => self.class.circuit_breaker_for("databursatil") }
      )
    end

    case asset.asset_type
    when "stock", "index", "etf"
      build_chain(
        [ MarketData::Gateways::FinnhubGateway, MarketData::Gateways::YahooFinanceGateway ],
        {
          "MarketData::Gateways::FinnhubGateway" => self.class.circuit_breaker_for("finnhub"),
          "MarketData::Gateways::YahooFinanceGateway" => self.class.circuit_breaker_for("yahoo_us")
        }
      )
    when "crypto"
      build_chain([ MarketData::Gateways::CoingeckoGateway ])
    else
      raise ArgumentError, "Unknown asset type: #{asset.asset_type}"
    end
  end

  # An unconfigured provider is skipped rather than raised, so a missing key
  # degrades to the next gateway instead of failing the job outright.
  def build_chain(gateway_classes, circuit_breakers = {})
    gateways = gateway_classes.filter_map do |klass|
      klass.new
    rescue MarketData::Gateways::ApiKeyNotConfiguredError
      nil
    end

    GatewayChain.new(gateways: gateways, circuit_breakers: circuit_breakers)
  end

  def update_asset(asset, data)
    old_price = asset.current_price

    update_attrs = {
      current_price: data[:price],
      change_percent_24h: data[:change_percent],
      volume: data[:volume] || asset.volume,
      market_cap: data[:market_cap] || asset.market_cap,
      price_updated_at: Time.current,
      last_synced_at: Time.current,
      last_sync_error: nil
    }
    update_attrs[:data_source] = data[:data_source] if data[:data_source]

    asset.update!(update_attrs)

    publish_price_update(asset, old_price, data[:price]) if price_changed?(old_price, data[:price])
  end

  def price_changed?(old_price, new_price)
    old_price.nil? || old_price.to_d != new_price.to_d
  end

  def publish_price_update(asset, old_price, new_price)
    EventBus.publish(MarketData::Events::AssetPriceUpdated.new(
      asset_id: asset.id,
      symbol: asset.symbol,
      old_price: (old_price || 0).to_s,
      new_price: new_price.to_s
    ))
  end

  def publish_all_gateways_failed(asset, attempted)
    EventBus.publish(MarketData::Events::AllGatewaysFailed.new(
      asset_id: asset.id,
      symbol: asset.symbol,
      attempted_gateways: Array(attempted)
    ))
  end
end
