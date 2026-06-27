Rails.application.config.after_initialize do
  # Identity
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::CreatePortfolioOnRegistration)
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::CreateAlertPreferencesOnRegistration)
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::SendWelcomeEmailOnRegistration)
  EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::SendVerificationEmailOnRegistration)
  EventBus.subscribe(Identity::Events::FirstAdminCreated, Identity::Handlers::CreatePortfolioOnRegistration)
  EventBus.subscribe(Identity::Events::FirstAdminCreated, Identity::Handlers::CreateAlertPreferencesOnRegistration)
  EventBus.subscribe(Identity::Events::PasswordChanged, Identity::Handlers::InvalidateSessionsOnPasswordChange)
  EventBus.subscribe(Identity::Events::PasswordChanged, Identity::Handlers::CreateAuditLogOnPasswordChange)
  EventBus.subscribe(Identity::Events::UserLoggedIn, Identity::Handlers::CreateAuditLogOnLogin)
  EventBus.subscribe(Identity::Events::UserLoginFailed, Identity::Handlers::CreateAuditLogOnLoginFailure)

  # Administration
  EventBus.subscribe(Identity::Events::UserSuspended, Administration::Handlers::CreateAuditLogOnSuspension)
  EventBus.subscribe(Identity::Events::UserSuspended, Administration::Handlers::SendSuspensionEmail)
  EventBus.subscribe(Identity::Events::UserReactivated, Administration::Handlers::CreateAuditLogOnReactivation)
  EventBus.subscribe(Identity::Events::UserReactivated, Administration::Handlers::SendReactivationEmail)
  EventBus.subscribe(Identity::Events::UserDeleted, Administration::Handlers::CreateAuditLogOnDeletion)
  EventBus.subscribe(Identity::Events::EmailVerified, Identity::Handlers::CreateAuditLogOnEmailVerification)
  EventBus.subscribe(Identity::Events::ProfileUpdated, Identity::Handlers::CreateAuditLogOnProfileUpdate)
  EventBus.subscribe(MarketData::Events::AssetCreated, Administration::Handlers::CreateAuditLogOnAssetCreation)
  EventBus.subscribe(MarketData::Events::AssetCreated, MarketData::Handlers::SyncAssetOnCreation)
  EventBus.subscribe(MarketData::Events::AssetCreated, MarketData::Handlers::BackfillHistoryOnAssetCreation)
  EventBus.subscribe(MarketData::Events::AssetDeleted, Administration::Handlers::CreateAuditLogOnAssetDeletion)
  EventBus.subscribe(Administration::Events::AssetUpdated, Administration::Handlers::CreateAuditLogOnAssetUpdate)
  EventBus.subscribe(Administration::Events::CsvExported, Administration::Handlers::CreateAuditLogOnCsvExport)

  # Market Data
  EventBus.subscribe(MarketData::Events::AssetPriceUpdated, Alerts::Handlers::EvaluateAlertsOnPriceUpdate)
  EventBus.subscribe(MarketData::Events::AssetPriceUpdated, MarketData::Handlers::BroadcastPriceUpdate)
  EventBus.subscribe(MarketData::Events::AssetPriceUpdated, MarketData::Handlers::RecordPriceHistory)
  EventBus.subscribe(MarketData::Events::AssetPriceUpdated, MarketData::Handlers::RecalculateTrendScoreOnPriceUpdate)
  EventBus.subscribe(MarketData::Events::AllGatewaysFailed, MarketData::Handlers::LogAllGatewaysFailure)

  # Alerts
  EventBus.subscribe(Alerts::Events::AlertRuleTriggered, Alerts::Handlers::CreateAlertEventOnTrigger)
  EventBus.subscribe(Alerts::Events::AlertRuleTriggered, Alerts::Handlers::CreateNotificationOnAlert)

  # Notifications
  EventBus.subscribe(Notifications::Events::NotificationCreated, Notifications::Handlers::BroadcastNotification)

  # Trading
  EventBus.subscribe(Trading::Events::TradeExecuted, Trading::Handlers::RecalculateAvgCostOnTrade)
  EventBus.subscribe(Trading::Events::TradeExecuted, Trading::Handlers::LogTradeActivity)
  EventBus.subscribe(Trading::Events::TradeUpdated, Trading::Handlers::LogTradeUpdate)
  EventBus.subscribe(Trading::Events::TradeDeleted, Trading::Handlers::LogTradeDelete)

  # UserActivity recording (#172) — domain events that map to JTBDs.
  EventBus.subscribe(Trading::Events::TradeExecuted,       Trading::Handlers::RecordTradeActivity)
  EventBus.subscribe(Trading::Events::WatchlistItemAdded,  Trading::Handlers::RecordWatchlistItemAddedActivity)
  EventBus.subscribe(Alerts::Events::RuleCreated,          Alerts::Handlers::RecordRuleCreatedActivity)

  # News
  EventBus.subscribe(MarketData::Events::NewsSynced, MarketData::Handlers::LogNewsSync)

  # Earnings
  EventBus.subscribe(MarketData::Events::EarningsSynced, MarketData::Handlers::LogEarningsSync)

  # Market Indices
  EventBus.subscribe(MarketData::Events::MarketIndicesUpdated, MarketData::Handlers::LogMarketIndicesUpdate)

  # Sentiment
  EventBus.subscribe(MarketData::Events::FearGreedUpdated, MarketData::Handlers::LogFearGreedUpdate)

  # Dividends
  EventBus.subscribe(MarketData::Events::DividendsSynced, MarketData::Handlers::LogDividendsSync)

  # Stock Splits
  EventBus.subscribe(Trading::Events::SplitDetected, Trading::Handlers::AdjustPositionsOnSplit)

  # CETES
  EventBus.subscribe(MarketData::Events::CetesSynced, MarketData::Handlers::LogCetesSync)

  # Fundamentals
  EventBus.subscribe(MarketData::Events::AssetFundamentalsUpdated, MarketData::Handlers::LogFundamentalsUpdate)
  EventBus.subscribe(MarketData::Events::AssetFundamentalsUpdated, MarketData::Handlers::BroadcastFundamentalsUpdate)
  EventBus.subscribe(MarketData::Events::FinancialStatementsSynced, MarketData::Handlers::RecalculateFundamentalsOnStatementsSynced)

  # Integrations
  EventBus.subscribe(Administration::Events::IntegrationConnected, Administration::Handlers::LogIntegrationConnected)
  EventBus.subscribe(Administration::Events::IntegrationUpdated, Administration::Handlers::LogIntegrationUpdated)
  EventBus.subscribe(Administration::Events::IntegrationDeleted, Administration::Handlers::LogIntegrationDeleted)
  EventBus.subscribe(Administration::Events::PoolKeyAdded, Administration::Handlers::LogPoolKeyChange)
  EventBus.subscribe(Administration::Events::PoolKeyToggled, Administration::Handlers::LogPoolKeyChange)
  EventBus.subscribe(Administration::Events::PoolKeyRemoved, Administration::Handlers::LogPoolKeyChange)
end
