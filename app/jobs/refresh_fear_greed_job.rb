# Fetches Fear & Greed indices from Alternative.me (crypto) and CNN (stocks).
# Each source is fetched independently — one failure doesn't block the other.
class RefreshFearGreedJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    fetch_crypto
    fetch_stocks
  end

  private

  def fetch_crypto
    result = crypto_breaker.call { CryptoFearGreedGateway.new.fetch_index }

    if result.success?
      save_reading("crypto", "alternative.me", result.value!)
    else
      log_sync_failure("Fear & Greed: crypto", result.failure[1], severity: failure_severity(result))
    end
  end

  def fetch_stocks
    result = stocks_breaker.call { StockFearGreedGateway.new.fetch_index }

    if result.success?
      save_reading("stocks", "cnn", result.value!)
    else
      log_sync_failure("Fear & Greed: stocks", result.failure[1], severity: failure_severity(result))
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

    EventBus.publish(FearGreedUpdated.new(
      index_type: index_type,
      value: reading.value,
      classification: reading.classification
    ))
  end

  def failure_severity(result)
    result.failure[0] == :rate_limited || result.failure[0] == :circuit_open ? :warning : :error
  end

  def crypto_breaker
    SyncSingleAssetJob.circuit_breaker_for("crypto_fear_greed")
  end

  def stocks_breaker
    SyncSingleAssetJob.circuit_breaker_for("stock_fear_greed")
  end
end
