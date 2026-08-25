class SyncCetesHistoryJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  def perform(term: "28", from: nil, to: Date.current)
    result = MarketData::UseCases::SyncCetesHistory.call(term: term, from: from, to: to)

    if result.success?
      log_sync_success("CETES History Sync", message: "#{result.value![:stored]} auctions stored")
    else
      log_sync_failure("CETES History Sync", result.failure[1])
    end
  end
end
