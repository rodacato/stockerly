class NotifyMaturitiesJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    sent = Trading::UseCases::NotifyApproachingMaturities.call.value!

    log_sync_success("Maturity Notifications", message: "#{sent} notifications sent")
  rescue StandardError => e
    log_sync_failure("Maturity Notifications", e.message)
    raise
  end
end
