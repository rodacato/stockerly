class LogCetesSync
  def self.call(event)
    count = event.is_a?(Hash) ? event[:count] : event.count

    SystemLog.create!(
      task_name: "CETES Sync",
      module_name: "sync",
      severity: :success,
      duration_seconds: 0,
      error_message: "#{count} CETES terms synced"
    )
  end
end
