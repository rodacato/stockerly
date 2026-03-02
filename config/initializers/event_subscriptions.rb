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
  EventBus.subscribe(Identity::UserSuspended, Administration::CreateAuditLogOnSuspension)
  EventBus.subscribe(Identity::UserSuspended, Administration::SendSuspensionEmail)
  EventBus.subscribe(MarketData::AssetCreated, Administration::CreateAuditLogOnAssetCreation)
  EventBus.subscribe(MarketData::AssetCreated, MarketData::SyncAssetOnCreation)
  EventBus.subscribe(MarketData::AssetCreated, MarketData::BackfillHistoryOnAssetCreation)

  # Market Data
  EventBus.subscribe(MarketData::AssetPriceUpdated, Alerts::EvaluateAlertsOnPriceUpdate)
  EventBus.subscribe(MarketData::AssetPriceUpdated, MarketData::BroadcastPriceUpdate)
  EventBus.subscribe(MarketData::AssetPriceUpdated, MarketData::RecordPriceHistory)
  EventBus.subscribe(MarketData::AssetPriceUpdated, MarketData::RecalculateTrendScoreOnPriceUpdate)
  EventBus.subscribe(MarketData::AllGatewaysFailed, MarketData::LogAllGatewaysFailure)

  # Alerts
  EventBus.subscribe(Alerts::AlertRuleTriggered, Alerts::CreateAlertEventOnTrigger)
  EventBus.subscribe(Alerts::AlertRuleTriggered, Alerts::CreateNotificationOnAlert)

  # Notifications
  EventBus.subscribe(Notifications::NotificationCreated, Notifications::BroadcastNotification)

  # Trading
  EventBus.subscribe(Trading::TradeExecuted, Trading::RecalculateAvgCostOnTrade)
  EventBus.subscribe(Trading::TradeExecuted, Trading::LogTradeActivity)
  EventBus.subscribe(Trading::TradeUpdated, Trading::LogTradeUpdate)
  EventBus.subscribe(Trading::TradeDeleted, Trading::LogTradeDelete)

  # News
  EventBus.subscribe(MarketData::NewsSynced, MarketData::LogNewsSync)

  # Earnings
  EventBus.subscribe(MarketData::EarningsSynced, MarketData::LogEarningsSync)

  # Market Indices
  EventBus.subscribe(MarketData::MarketIndicesUpdated, MarketData::LogMarketIndicesUpdate)

  # Sentiment
  EventBus.subscribe(MarketData::FearGreedUpdated, MarketData::LogFearGreedUpdate)
  EventBus.subscribe(MarketData::FearGreedUpdated, Alerts::EvaluateSentimentAlerts)

  # Dividends
  EventBus.subscribe(MarketData::DividendsSynced, MarketData::LogDividendsSync)

  # Stock Splits
  EventBus.subscribe(Trading::SplitDetected, Trading::AdjustPositionsOnSplit)

  # CETES
  EventBus.subscribe(MarketData::CetesSynced, MarketData::LogCetesSync)

  # Fundamentals
  EventBus.subscribe(MarketData::AssetFundamentalsUpdated, MarketData::LogFundamentalsUpdate)
  EventBus.subscribe(MarketData::AssetFundamentalsUpdated, MarketData::BroadcastFundamentalsUpdate)
  EventBus.subscribe(MarketData::FinancialStatementsSynced, MarketData::RecalculateFundamentalsOnStatementsSynced)

  # Integrations
  EventBus.subscribe(Administration::IntegrationConnected, Administration::LogIntegrationConnected)
  EventBus.subscribe(Administration::IntegrationUpdated, Administration::LogIntegrationUpdated)
  EventBus.subscribe(Administration::IntegrationDeleted, Administration::LogIntegrationDeleted)
  EventBus.subscribe(Administration::PoolKeyAdded, Administration::LogPoolKeyChange)
  EventBus.subscribe(Administration::PoolKeyToggled, Administration::LogPoolKeyChange)
  EventBus.subscribe(Administration::PoolKeyRemoved, Administration::LogPoolKeyChange)
end
