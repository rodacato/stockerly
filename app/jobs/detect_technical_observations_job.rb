class DetectTechnicalObservationsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  # One run per calendar, each at its own close (D126).
  def perform(calendar)
    detected = MarketData::UseCases::DetectTechnicalObservations.call(calendar: calendar.to_sym)

    log_sync_success("Technical Observations", message: "#{detected} observations detected")
  rescue StandardError => e
    log_sync_failure("Technical Observations", e.message)
    raise
  end
end
