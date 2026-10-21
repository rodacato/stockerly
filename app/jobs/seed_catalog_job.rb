class SeedCatalogJob < ApplicationJob
  include SyncLogging

  TASK = "Maintenance: asset catalogue".freeze

  queue_as :default

  def perform
    result = Administration::UseCases::Assets::SeedCatalog.call
    message = "#{result[:created]} created, #{result[:corrected]} corrected, #{result[:total]} total"

    return log_sync_success(TASK, message: message) if result[:skipped].empty?

    log_sync_failure(TASK, "#{message}; left alone (has trades): #{result[:skipped].join(', ')}", severity: :warning)
  end
end
