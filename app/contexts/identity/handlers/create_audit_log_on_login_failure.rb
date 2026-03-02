module Identity
  class CreateAuditLogOnLoginFailure
    def self.call(event)
      email = event.is_a?(Hash) ? event[:email] : event.email
      ip_address = event.is_a?(Hash) ? event[:ip_address] : event.ip_address
      user_agent = event.is_a?(Hash) ? event[:user_agent] : event.user_agent

      user = User.find_by(email: email.downcase.strip)
      return unless user

      AuditLog.create!(
        user_id: user.id,
        action: "login_failed",
        changes_data: { ip_address: ip_address, user_agent: user_agent }
      )
    end
  end
end
