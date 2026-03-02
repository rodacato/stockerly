module Identity
  class CreateAuditLogOnLogin
    def self.call(event)
      user_id = event.is_a?(Hash) ? event[:user_id] : event.user_id
      ip_address = event.is_a?(Hash) ? event[:ip_address] : event.ip_address
      user_agent = event.is_a?(Hash) ? event[:user_agent] : event.user_agent

      AuditLog.create!(
        user_id: user_id,
        action: "user_logged_in",
        changes_data: { ip_address: ip_address, user_agent: user_agent }
      )
    end
  end
end
