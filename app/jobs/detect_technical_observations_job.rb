class DetectTechnicalObservationsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    detected = MarketData::UseCases::DetectTechnicalObservations.call.value!

    log_sync_success("Technical Observations", message: "#{detected} observations detected")
  rescue StandardError => e
    log_sync_failure("Technical Observations", e.message)
    raise
  end
end
