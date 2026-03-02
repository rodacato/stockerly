class CreateAuditLogOnPasswordChange
  def self.call(event)
    user_id = event.is_a?(Hash) ? event[:user_id] : event.user_id

    AuditLog.create!(
      user_id: user_id,
      action: "password_changed",
      changes_data: {}
    )
  end
end
