# Banxico publishes the FIX each business day around noon CDMX (#177); this runs
# after that. It asks for a week back, not just today, so a missed run or a
# holiday gap heals itself on the next pass.
class SyncFxHistoryJob < ApplicationJob
  include PausableSync
  include SyncLogging
  queue_as :default

  LOOKBACK_DAYS = 7

  def perform(days: LOOKBACK_DAYS)
    started = Time.current
    result = MarketData::UseCases::SyncFxHistory.call(from: Date.current - days, to: Date.current)
    duration = (Time.current - started).round(2)

    case result
    in Dry::Monads::Success(stored:, **)
      log_sync_success("FX History Sync", message: "Stored #{stored} FIX rate(s)", duration_seconds: duration)
    in Dry::Monads::Failure[ _, message ]
      log_sync_failure("FX History Sync", message, duration_seconds: duration)
    end
  end
end
