class NotifyMaturitiesJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    result = Trading::UseCases::NotifyApproachingMaturities.call

    if result.success?
      log_sync_success("Maturity Notifications", message: "#{result.value!} notifications sent")
    else
      log_sync_failure("Maturity Notifications", result.failure[1])
    end
  end
end
