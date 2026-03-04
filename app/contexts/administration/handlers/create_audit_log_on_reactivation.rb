module Administration
  module Handlers
    class CreateAuditLogOnReactivation
      def self.call(event)
        event = event.symbolize_keys if event.is_a?(Hash)
        user_id = event.is_a?(Hash) ? event[:admin_id] : event.admin_id
        target_id = event.is_a?(Hash) ? event[:user_id] : event.user_id

        AuditLog.create!(
          user_id: user_id,
          action: "user_reactivated",
          changes_data: { reactivated_user_id: target_id }
        )
      end
    end
  end
end
