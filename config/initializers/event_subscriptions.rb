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
  EventBus.subscribe(AssetCreated, SyncAssetOnCreation)
  EventBus.subscribe(AssetCreated, BackfillHistoryOnAssetCreation)

  # Market Data
  EventBus.subscribe(AssetPriceUpdated, EvaluateAlertsOnPriceUpdate)
  EventBus.subscribe(AssetPriceUpdated, BroadcastPriceUpdate)
  EventBus.subscribe(AssetPriceUpdated, RecordPriceHistory)
  EventBus.subscribe(AllGatewaysFailed, LogAllGatewaysFailure)

  # Alerts
  EventBus.subscribe(AlertRuleTriggered, CreateAlertEventOnTrigger)
  EventBus.subscribe(AlertRuleTriggered, CreateNotificationOnAlert)

  # Notifications
  EventBus.subscribe(NotificationCreated, BroadcastNotification)

  # Trading
  EventBus.subscribe(TradeExecuted, RecalculateAvgCostOnTrade)
  EventBus.subscribe(TradeExecuted, LogTradeActivity)

  # Sentiment
  EventBus.subscribe(FearGreedUpdated, LogFearGreedUpdate)

  # Integrations
  EventBus.subscribe(IntegrationConnected, LogIntegrationConnected)
end
