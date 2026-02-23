class LogFearGreedUpdate
  def self.call(event)
    index_type     = event.is_a?(Hash) ? event[:index_type] : event.index_type
    value          = event.is_a?(Hash) ? event[:value] : event.value
    classification = event.is_a?(Hash) ? event[:classification] : event.classification

    SystemLog.create!(
      task_name: "Fear & Greed Update: #{index_type}",
      module_name: "sync",
      severity: :success,
      duration_seconds: 0,
      error_message: "Value: #{value} (#{classification})"
    )
  end
end
