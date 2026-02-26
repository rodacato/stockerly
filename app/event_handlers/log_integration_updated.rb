class LogIntegrationUpdated
  def self.call(event)
    provider_name = event.is_a?(Hash) ? event[:provider_name] : event.provider_name

    SystemLog.create!(
      task_name: "Integration Updated: #{provider_name}",
      module_name: "integrations",
      severity: :success,
      duration_seconds: 0
    )
  end
end
