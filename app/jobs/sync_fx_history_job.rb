# Banxico publishes the FIX each business day around noon CDMX (#177); this runs
# after that. It asks for a week back, not just today, so a missed run or a
# holiday gap heals itself on the next pass.
class SyncFxHistoryJob < ApplicationJob
  include PausableSync
  queue_as :default

  LOOKBACK_DAYS = 7

  def perform(days: LOOKBACK_DAYS)
    started = Time.current
    result = MarketData::UseCases::SyncFxHistory.call(from: Date.current - days, to: Date.current)

    case result
    in Dry::Monads::Success(stored:, **)
      log(:success, "Stored #{stored} FIX rate(s)", started)
    in Dry::Monads::Failure[ _, message ]
      log(:error, message, started)
    end
  end

  private

  def log(severity, message, started)
    SystemLog.create!(
      task_name: "FX History Sync",
      module_name: "sync",
      severity: severity,
      message: message,
      duration_seconds: (Time.current - started).round(2)
    )
  end
end
