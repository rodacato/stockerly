class SyncEarningsJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  def perform
    synced = MarketData::UseCases::SyncEarnings.call.value!

    log_sync_success("Earnings Sync", message: "#{synced} events synced")
  rescue StandardError => e
    log_sync_failure("Earnings Sync", e.message)
    raise
  end
end
