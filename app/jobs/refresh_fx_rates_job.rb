# Refreshes foreign exchange rates from the external API. Success/failure
# already lands in the SyncLog table via SyncLogging — there's no separate
# audience for an FxRatesRefreshed event, so #35 removed the publish call
# and dropped the event class.
class RefreshFxRatesJob < ApplicationJob
  include SyncLogging

  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  def perform
    result = MarketData::Gateways::FxRatesGateway.new.refresh_rates

    if result.success?
      log_sync_success("FX Rate Refresh")
    else
      log_sync_failure("FX Rate Refresh", result.failure[1])
    end
  end
end
