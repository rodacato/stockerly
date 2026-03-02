Rails.application.config.after_initialize do
  # Identity
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::CreatePortfolioOnRegistration)
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::CreateAlertPreferencesOnRegistration)
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::SendWelcomeEmailOnRegistration)
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::SendVerificationEmailOnRegistration)
  EventBus.subscribe(Identity::Events::PasswordChanged, Identity::Handlers::InvalidateSessionsOnPasswordChange)
  EventBus.subscribe(Identity::Events::PasswordChanged, Identity::Handlers::CreateAuditLogOnPasswordChange)
  EventBus.subscribe(Identity::Events::UserLoggedIn, Identity::Handlers::CreateAuditLogOnLogin)
  EventBus.subscribe(Identity::Events::UserLoginFailed, Identity::Handlers::CreateAuditLogOnLoginFailure)

  # Administration
  EventBus.subscribe(Identity::Events::UserSuspended, Administration::CreateAuditLogOnSuspension)
  EventBus.subscribe(Identity::Events::UserSuspended, Administration::SendSuspensionEmail)
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
  EventBus.subscribe(Notifications::Events::NotificationCreated, Notifications::Handlers::BroadcastNotification)

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
