class DetectTechnicalObservationsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    result = MarketData::UseCases::DetectTechnicalObservations.call

    if result.success?
      log_sync_success("Technical Observations", message: "#{result.value!} observations detected")
    else
      log_sync_failure("Technical Observations", result.failure[1])
    end
  end
end
