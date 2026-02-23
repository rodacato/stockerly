Rails.application.config.after_initialize do
  # Identity
  EventBus.subscribe(UserRegistered, CreatePortfolioOnRegistration)
  EventBus.subscribe(UserRegistered, CreateAlertPreferencesOnRegistration)
  EventBus.subscribe(UserRegistered, SendWelcomeEmailOnRegistration)
  EventBus.subscribe(PasswordChanged, InvalidateSessionsOnPasswordChange)

  # Administration
  EventBus.subscribe(UserSuspended, CreateAuditLogOnSuspension)
  EventBus.subscribe(UserSuspended, SendSuspensionEmail)
  EventBus.subscribe(AssetCreated, CreateAuditLogOnAssetCreation)

  # Market Data
  EventBus.subscribe(AssetPriceUpdated, EvaluateAlertsOnPriceUpdate)
  EventBus.subscribe(AssetPriceUpdated, BroadcastPriceUpdate)

  # Alerts
  EventBus.subscribe(AlertRuleTriggered, CreateAlertEventOnTrigger)
  EventBus.subscribe(AlertRuleTriggered, CreateNotificationOnAlert)

  # Notifications
  EventBus.subscribe(NotificationCreated, BroadcastNotification)

  # Trading
  EventBus.subscribe(TradeExecuted, RecalculateAvgCostOnTrade)
  EventBus.subscribe(TradeExecuted, LogTradeActivity)

  # Integrations
  EventBus.subscribe(IntegrationConnected, LogIntegrationConnected)
end
