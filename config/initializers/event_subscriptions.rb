Rails.application.config.after_initialize do
  # Identity
  EventBus.subscribe(UserRegistered, CreatePortfolioOnRegistration)
  EventBus.subscribe(UserRegistered, CreateAlertPreferencesOnRegistration)
  EventBus.subscribe(PasswordChanged, InvalidateSessionsOnPasswordChange)

  # Administration
  EventBus.subscribe(UserSuspended, CreateAuditLogOnSuspension)
end
