# Refreshes foreign exchange rates from the external API.
# Publishes FxRatesRefreshed event on success.
class RefreshFxRatesJob < ApplicationJob
  queue_as :default

  retry_on Faraday::Error, wait: :polynomially_longer, attempts: 3

  def perform
    result = FxRatesGateway.new.refresh_rates

    if result.success?
      log_success
      publish_event
    else
      log_failure(result.failure[1])
    end
  end

  private

  def log_success
    SystemLog.create!(
      task_name: "FX Rate Refresh",
      module_name: "sync",
      severity: :success,
      duration_seconds: 0
    )
  end

  def log_failure(message)
    SystemLog.create!(
      task_name: "FX Rate Refresh",
      module_name: "sync",
      severity: :error,
      error_message: message
    )
  end

  def publish_event
    EventBus.publish(FxRatesRefreshed.new)
  end
end
