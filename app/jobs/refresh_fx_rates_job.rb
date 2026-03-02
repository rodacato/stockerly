# Refreshes foreign exchange rates from the external API.
# Publishes MarketData::FxRatesRefreshed event on success.
class RefreshFxRatesJob < ApplicationJob
  include SyncLogging

  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  def perform
    result = MarketData::FxRatesGateway.new.refresh_rates

    if result.success?
      log_sync_success("FX Rate Refresh")
      EventBus.publish(MarketData::FxRatesRefreshed.new)
    else
      log_sync_failure("FX Rate Refresh", result.failure[1])
    end
  end
end
