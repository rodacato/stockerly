class SendDailyDigestJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    sent = Notifications::UseCases::SendDailyDigest.call.value!

    log_sync_success("Daily Digest", message: "#{sent} digest(s) sent")
  rescue StandardError => e
    log_sync_failure("Daily Digest", e.message)
    raise
  end
end
