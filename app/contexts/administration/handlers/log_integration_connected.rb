module Administration
  class LogIntegrationConnected
    def self.call(event)
      integration_id = event.is_a?(Hash) ? event[:integration_id] : event.integration_id
      provider_name  = event.is_a?(Hash) ? event[:provider_name] : event.provider_name

      SystemLog.create!(
        task_name: "Integration Connected: #{provider_name}",
        module_name: "integrations",
        severity: :success,
        duration_seconds: 0
      )
    end
  end
end
