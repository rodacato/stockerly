class SendDailyDigestJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    result = Notifications::UseCases::SendDailyDigest.call

    if result.success?
      log_sync_success("Daily Digest", message: "#{result.value!} digest(s) sent")
    else
      log_sync_failure("Daily Digest", result.failure[1])
    end
  end
end
