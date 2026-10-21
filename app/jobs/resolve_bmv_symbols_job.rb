# Maintenance: maps the Mexican assets that have no DataBursatil name yet.
# Run from the maintenance panel; idempotent, so a second run finds nothing.
class ResolveBmvSymbolsJob < ApplicationJob
  include SyncLogging

  TASK = "Maintenance: BMV symbols".freeze

  queue_as :default

  def perform
    outcome = Administration::UseCases::Assets::ResolveBmvSymbols.call
    message = "Resolved #{outcome.resolved.size}, unresolved #{outcome.unresolved.size}"

    return log_sync_success(TASK, message: message) if outcome.unresolved.empty?

    log_sync_failure(TASK, "#{message}: #{outcome.unresolved.join(', ')}", severity: :warning)
  rescue MarketData::Gateways::ApiKeyNotConfiguredError
    log_sync_failure(TASK, "DataBursatil has no API key configured")
  end
end
