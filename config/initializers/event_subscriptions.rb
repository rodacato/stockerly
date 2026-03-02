Rails.application.config.after_initialize do
  # Identity
  EventBus.subscribe(Identity::UserRegistered, Identity::CreatePortfolioOnRegistration)
  EventBus.subscribe(Identity::UserRegistered, Identity::CreateAlertPreferencesOnRegistration)
  EventBus.subscribe(Identity::UserRegistered, Identity::SendWelcomeEmailOnRegistration)
  EventBus.subscribe(Identity::UserRegistered, Identity::SendVerificationEmailOnRegistration)
  EventBus.subscribe(Identity::PasswordChanged, Identity::InvalidateSessionsOnPasswordChange)
  EventBus.subscribe(Identity::PasswordChanged, Identity::CreateAuditLogOnPasswordChange)
  EventBus.subscribe(Identity::UserLoggedIn, Identity::CreateAuditLogOnLogin)
  EventBus.subscribe(Identity::UserLoginFailed, Identity::CreateAuditLogOnLoginFailure)

  # Administration
  EventBus.subscribe(Identity::UserSuspended, CreateAuditLogOnSuspension)
  EventBus.subscribe(Identity::UserSuspended, SendSuspensionEmail)
  EventBus.subscribe(AssetCreated, CreateAuditLogOnAssetCreation)
  EventBus.subscribe(AssetCreated, SyncAssetOnCreation)
  EventBus.subscribe(AssetCreated, BackfillHistoryOnAssetCreation)

  # Market Data
  EventBus.subscribe(AssetPriceUpdated, Alerts::EvaluateAlertsOnPriceUpdate)
  EventBus.subscribe(AssetPriceUpdated, BroadcastPriceUpdate)
  EventBus.subscribe(AssetPriceUpdated, RecordPriceHistory)
  EventBus.subscribe(AssetPriceUpdated, RecalculateTrendScoreOnPriceUpdate)
  EventBus.subscribe(AllGatewaysFailed, LogAllGatewaysFailure)

  # Alerts
  EventBus.subscribe(Alerts::AlertRuleTriggered, Alerts::CreateAlertEventOnTrigger)
  EventBus.subscribe(Alerts::AlertRuleTriggered, Alerts::CreateNotificationOnAlert)

  # Notifications
  EventBus.subscribe(NotificationCreated, BroadcastNotification)

  # Trading
  EventBus.subscribe(TradeExecuted, RecalculateAvgCostOnTrade)
  EventBus.subscribe(TradeExecuted, LogTradeActivity)
  EventBus.subscribe(TradeUpdated, LogTradeUpdate)
  EventBus.subscribe(TradeDeleted, LogTradeDelete)

  # News
  EventBus.subscribe(NewsSynced, LogNewsSync)

  # Earnings
  EventBus.subscribe(EarningsSynced, LogEarningsSync)

  # Market Indices
  EventBus.subscribe(MarketIndicesUpdated, LogMarketIndicesUpdate)

  # Sentiment
  EventBus.subscribe(FearGreedUpdated, LogFearGreedUpdate)
  EventBus.subscribe(FearGreedUpdated, Alerts::EvaluateSentimentAlerts)

  # Dividends
  EventBus.subscribe(DividendsSynced, LogDividendsSync)

  # Stock Splits
  EventBus.subscribe(SplitDetected, AdjustPositionsOnSplit)

  # CETES
  EventBus.subscribe(CetesSynced, LogCetesSync)

  # Fundamentals
  EventBus.subscribe(AssetFundamentalsUpdated, LogFundamentalsUpdate)
  EventBus.subscribe(AssetFundamentalsUpdated, BroadcastFundamentalsUpdate)
  EventBus.subscribe(FinancialStatementsSynced, RecalculateFundamentalsOnStatementsSynced)

  # Integrations
  EventBus.subscribe(IntegrationConnected, LogIntegrationConnected)
  EventBus.subscribe(IntegrationUpdated, LogIntegrationUpdated)
  EventBus.subscribe(IntegrationDeleted, LogIntegrationDeleted)
  EventBus.subscribe(PoolKeyAdded, LogPoolKeyChange)
  EventBus.subscribe(PoolKeyToggled, LogPoolKeyChange)
  EventBus.subscribe(PoolKeyRemoved, LogPoolKeyChange)
end
