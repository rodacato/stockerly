class SyncCetesJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    result = MarketData::UseCases::SyncCetes.call

    if result.success?
      log_sync_success("CETES Sync", message: "#{result.value!} terms synced")
    else
      log_sync_failure("CETES Sync", result.failure[1])
    end
  end
end
