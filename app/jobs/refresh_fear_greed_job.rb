# Fetches the crypto Fear & Greed index from Alternative.me.
# The stocks index went with CNN's gateway: its endpoint blocks datacenter
# IPs outright and no sanctioned equivalent exists (ADR-015's audit).
class RefreshFearGreedJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  def perform
    fetch_crypto
  end

  private

  def fetch_crypto
    result = crypto_breaker.call { MarketData::Gateways::CryptoFearGreedGateway.new.fetch_index }

    if result.success?
      save_reading("crypto", "alternative.me", result.value!)
    else
      log_sync_failure("Fear & Greed: crypto", result.failure[1], severity: failure_severity(result))
    end
  end

  def save_reading(index_type, source, data)
    reading = FearGreedReading.create!(
      index_type: index_type,
      value: data[:value],
      classification: data[:classification],
      source: source,
      component_data: data[:component_data] || {},
      fetched_at: data[:fetched_at]
    )

    log_sync_success("Fear & Greed: #{index_type}")

    EventBus.publish(MarketData::Events::FearGreedUpdated.new(
      index_type: index_type,
      value: reading.value,
      classification: reading.classification
    ))
  end

  def failure_severity(result)
    result.failure[0] == :rate_limited || result.failure[0] == :circuit_open ? :warning : :error
  end

  def crypto_breaker
    GatewayChain.breaker_for("crypto_fear_greed")
  end
end
