module Administration
  module Handlers
    class CreateAuditLogOnDeletion
      def self.call(event)
        event = event.symbolize_keys if event.is_a?(Hash)
        admin_id  = event.is_a?(Hash) ? event[:admin_id]  : event.admin_id
        user_id   = event.is_a?(Hash) ? event[:user_id]   : event.user_id
        email     = event.is_a?(Hash) ? event[:email]     : event.email
        full_name = event.is_a?(Hash) ? event[:full_name] : event.full_name

        AuditLog.create!(
          user_id: admin_id,
          action: "user_deleted",
          changes_data: {
            deleted_user_id: user_id,
            deleted_email: email,
            deleted_full_name: full_name
          }
        )
      end
    end
  end
end
