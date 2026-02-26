class LogIntegrationDeleted
  def self.call(event)
    provider_name = event.is_a?(Hash) ? event[:provider_name] : event.provider_name

    SystemLog.create!(
      task_name: "Integration Deleted: #{provider_name}",
      module_name: "integrations",
      severity: :warning,
      duration_seconds: 0
    )
  end
end
