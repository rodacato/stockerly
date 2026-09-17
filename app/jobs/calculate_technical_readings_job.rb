class CalculateTechnicalReadingsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    refreshed = MarketData::UseCases::RefreshTechnicalReadings.call

    log_sync_success("Technical Readings", message: "#{refreshed} readings refreshed")
  rescue StandardError => e
    log_sync_failure("Technical Readings", e.message)
    raise
  end
end
