class SyncEarningsJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    result = Earnings::SyncCalendar.call

    if result.success?
      log_sync_success("Earnings Sync", message: "#{result.value!} events synced")
    else
      log_sync_failure("Earnings Sync", result.failure[1])
    end
  end
end
