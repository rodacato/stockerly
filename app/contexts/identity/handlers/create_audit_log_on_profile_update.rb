module Identity
  module Handlers
    # Audit: user edited their profile. The current event payload only
    # carries user_id — a future enhancement could include the diff of
    # changed fields, but for now an "it happened" row is enough to
    # satisfy the audit-trail expectation.
    class CreateAuditLogOnProfileUpdate
      def self.call(event)
        AuditLog.create!(
          user_id: event.user_id,
          action: "profile_updated"
        )
      end
    end
  end
end
