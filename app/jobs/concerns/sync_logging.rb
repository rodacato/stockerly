# Standardized logging for sync jobs. Eliminates duplicated
# SystemLog.create! blocks across all sync/refresh jobs.
module SyncLogging
  extend ActiveSupport::Concern

  private

  def log_sync_success(task_name, message: nil)
    SystemLog.create!(
      task_name: task_name,
      module_name: "sync",
      severity: :success,
      duration_seconds: 0,
      error_message: message
    )
  end

  def log_sync_failure(task_name, message, severity: :error)
    SystemLog.create!(
      task_name: task_name,
      module_name: "sync",
      severity: severity,
      error_message: message
    )
  end
end
