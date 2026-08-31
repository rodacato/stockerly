class SyncCetesJob < ApplicationJob
  include PausableSync
  include SyncLogging

  queue_as :default

  def perform
    result = MarketData::UseCases::SyncCetes.call

    case result
    in Dry::Monads::Success(synced:, unreachable:)
      report("CETES Sync", "#{synced} terms synced",
             unreachable: unreachable, total: MarketData::UseCases::SyncCetes::TERMS.size)
    in Dry::Monads::Failure[ _, message ]
      log_sync_failure("CETES Sync", message)
    end
  end
end
