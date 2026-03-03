module Administration
  module Handlers
    class LogPoolKeyChange
      def self.call(event)
        key_name = event.is_a?(Hash) ? event[:key_name] : event.key_name
        action = case event
        when Administration::Events::PoolKeyAdded then "Added"
        when Administration::Events::PoolKeyToggled
          enabled = event.is_a?(Hash) ? event[:enabled] : event.enabled
          enabled ? "Enabled" : "Disabled"
        when Administration::Events::PoolKeyRemoved then "Removed"
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
  end
end
