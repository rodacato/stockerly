class LogPoolKeyChange
  def self.call(event)
    key_name = event.is_a?(Hash) ? event[:key_name] : event.key_name
    action = case event
    when PoolKeyAdded then "Added"
    when PoolKeyToggled
      enabled = event.is_a?(Hash) ? event[:enabled] : event.enabled
      enabled ? "Enabled" : "Disabled"
    when PoolKeyRemoved then "Removed"
    else "Changed"
    end

    SystemLog.create!(
      task_name: "Pool Key #{action}: #{key_name}",
      module_name: "integrations",
      severity: action == "Removed" ? :warning : :success,
      duration_seconds: 0
    )
  end
end
