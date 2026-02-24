Rails.application.config.after_initialize do
  # Identity
  EventBus.subscribe(UserRegistered, CreatePortfolioOnRegistration)
  EventBus.subscribe(UserRegistered, CreateAlertPreferencesOnRegistration)
  EventBus.subscribe(UserRegistered, SendWelcomeEmailOnRegistration)
  EventBus.subscribe(UserRegistered, SendVerificationEmailOnRegistration)
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
  EventBus.subscribe(AssetPriceUpdated, RecalculateTrendScoreOnPriceUpdate)
  EventBus.subscribe(AllGatewaysFailed, LogAllGatewaysFailure)

  # Alerts
  EventBus.subscribe(AlertRuleTriggered, CreateAlertEventOnTrigger)
  EventBus.subscribe(AlertRuleTriggered, CreateNotificationOnAlert)

  # Notifications
  EventBus.subscribe(NotificationCreated, BroadcastNotification)

  # Trading
  EventBus.subscribe(TradeExecuted, RecalculateAvgCostOnTrade)
  EventBus.subscribe(TradeExecuted, LogTradeActivity)

  # News
  EventBus.subscribe(NewsSynced, LogNewsSync)

  # Earnings
  EventBus.subscribe(EarningsSynced, LogEarningsSync)

  # Market Indices
  EventBus.subscribe(MarketIndicesUpdated, LogMarketIndicesUpdate)

  # Sentiment
  EventBus.subscribe(FearGreedUpdated, LogFearGreedUpdate)

  # Fundamentals
  EventBus.subscribe(AssetFundamentalsUpdated, LogFundamentalsUpdate)
  EventBus.subscribe(AssetFundamentalsUpdated, BroadcastFundamentalsUpdate)
  EventBus.subscribe(FinancialStatementsSynced, RecalculateFundamentalsOnStatementsSynced)

  # Integrations
  EventBus.subscribe(IntegrationConnected, LogIntegrationConnected)
end
