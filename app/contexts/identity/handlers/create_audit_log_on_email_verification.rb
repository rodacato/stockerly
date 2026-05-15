module Identity
  module Handlers
    # Audit: user clicked the verification link. Captures the verified
    # email at the moment of verification (in case the user later
    # changes their email address).
    class CreateAuditLogOnEmailVerification
      def self.call(event)
        AuditLog.create!(
          user_id: event.user_id,
          action: "email_verified",
          changes_data: { email: event.email }
        )
      end
    end
  end
end
