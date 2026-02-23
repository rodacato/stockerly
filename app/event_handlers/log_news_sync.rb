class LogNewsSync
  def self.call(event)
    count = event.is_a?(Hash) ? event[:count] : event.count

    SystemLog.create!(
      task_name: "News Sync",
      module_name: "sync",
      severity: :success,
      duration_seconds: 0,
      error_message: "#{count} new articles imported"
    )
  end
end
