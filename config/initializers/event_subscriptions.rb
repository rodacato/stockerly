Rails.application.config.after_initialize do
  # Identity
  EventBus.subscribe(UserRegistered, CreatePortfolioOnRegistration)
  EventBus.subscribe(UserRegistered, CreateAlertPreferencesOnRegistration)
  EventBus.subscribe(UserRegistered, SendWelcomeEmailOnRegistration)
  EventBus.subscribe(UserRegistered, SendVerificationEmailOnRegistration)
  EventBus.subscribe(PasswordChanged, InvalidateSessionsOnPasswordChange)
  EventBus.subscribe(PasswordChanged, CreateAuditLogOnPasswordChange)
  EventBus.subscribe(UserLoggedIn, CreateAuditLogOnLogin)
  EventBus.subscribe(UserLoginFailed, CreateAuditLogOnLoginFailure)

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
  EventBus.subscribe(FearGreedUpdated, EvaluateSentimentAlerts)

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
