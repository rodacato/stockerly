class NotifyEarningsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    result = Earnings::NotifyApproaching.call

    if result.success?
      log_sync_success("Earnings Notifications", message: "#{result.value!} notifications sent")
    else
      log_sync_failure("Earnings Notifications", result.failure[1])
    end
  end
end
