class NotifyEarningsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    sent = MarketData::UseCases::NotifyApproachingEarnings.call

    log_sync_success("Earnings Notifications", message: "#{sent} notifications sent")
  rescue StandardError => e
    log_sync_failure("Earnings Notifications", e.message)
    raise
  end
end
