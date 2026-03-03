require "rails_helper"

RSpec.describe "Event Subscription Wiring" do
  # Reload subscriptions (cleared by EventBus.clear! in each test)
  before { load Rails.root.join("config/initializers/event_subscriptions.rb") }

  # ---------------------------------------------------------------------------
  # Identity
  # ---------------------------------------------------------------------------
  describe "Identity subscriptions" do
    describe "Identity::Events::UserRegistered" do
      it "has portfolio, alert prefs, welcome email, and verification email handlers" do
        handlers = EventBus.handlers_for(Identity::Events::UserRegistered)

        expect(handlers).to include(Identity::Handlers::CreatePortfolioOnRegistration)
        expect(handlers).to include(Identity::Handlers::CreateAlertPreferencesOnRegistration)
        expect(handlers).to include(Identity::Handlers::SendWelcomeEmailOnRegistration)
        expect(handlers).to include(Identity::Handlers::SendVerificationEmailOnRegistration)
      end
    end

    describe "Identity::Events::PasswordChanged" do
      it "has session invalidation and audit log handlers" do
        handlers = EventBus.handlers_for(Identity::Events::PasswordChanged)

        expect(handlers).to include(Identity::Handlers::InvalidateSessionsOnPasswordChange)
        expect(handlers).to include(Identity::Handlers::CreateAuditLogOnPasswordChange)
      end
    end

    describe "Identity::Events::UserLoggedIn" do
      it "has audit log handler" do
        handlers = EventBus.handlers_for(Identity::Events::UserLoggedIn)

        expect(handlers).to include(Identity::Handlers::CreateAuditLogOnLogin)
      end
    end

    describe "Identity::Events::UserLoginFailed" do
      it "has audit log handler" do
        handlers = EventBus.handlers_for(Identity::Events::UserLoginFailed)

        expect(handlers).to include(Identity::Handlers::CreateAuditLogOnLoginFailure)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Administration
  # ---------------------------------------------------------------------------
  describe "Administration subscriptions" do
    describe "Identity::Events::UserSuspended" do
      it "has audit log and suspension email handlers" do
        handlers = EventBus.handlers_for(Identity::Events::UserSuspended)

        expect(handlers).to include(Administration::Handlers::CreateAuditLogOnSuspension)
        expect(handlers).to include(Administration::Handlers::SendSuspensionEmail)
      end
    end

    describe "MarketData::Events::AssetCreated" do
      it "has audit log, sync, and backfill history handlers" do
        handlers = EventBus.handlers_for(MarketData::Events::AssetCreated)

        expect(handlers).to include(Administration::Handlers::CreateAuditLogOnAssetCreation)
        expect(handlers).to include(MarketData::Handlers::SyncAssetOnCreation)
        expect(handlers).to include(MarketData::Handlers::BackfillHistoryOnAssetCreation)
      end
    end

    describe "Administration::Events::IntegrationConnected" do
      it "has Administration::Handlers::LogIntegrationConnected handler" do
        handlers = EventBus.handlers_for(Administration::Events::IntegrationConnected)

        expect(handlers).to include(Administration::Handlers::LogIntegrationConnected)
      end
    end

    describe "Administration::Events::IntegrationUpdated" do
      it "has Administration::Handlers::LogIntegrationUpdated handler" do
        handlers = EventBus.handlers_for(Administration::Events::IntegrationUpdated)

        expect(handlers).to include(Administration::Handlers::LogIntegrationUpdated)
      end
    end

    describe "Administration::Events::IntegrationDeleted" do
      it "has Administration::Handlers::LogIntegrationDeleted handler" do
        handlers = EventBus.handlers_for(Administration::Events::IntegrationDeleted)

        expect(handlers).to include(Administration::Handlers::LogIntegrationDeleted)
      end
    end

    describe "Administration::Events::PoolKeyAdded" do
      it "has Administration::Handlers::LogPoolKeyChange handler" do
        handlers = EventBus.handlers_for(Administration::Events::PoolKeyAdded)

        expect(handlers).to include(Administration::Handlers::LogPoolKeyChange)
      end
    end

    describe "Administration::Events::PoolKeyToggled" do
      it "has Administration::Handlers::LogPoolKeyChange handler" do
        handlers = EventBus.handlers_for(Administration::Events::PoolKeyToggled)

        expect(handlers).to include(Administration::Handlers::LogPoolKeyChange)
      end
    end

    describe "Administration::Events::PoolKeyRemoved" do
      it "has Administration::Handlers::LogPoolKeyChange handler" do
        handlers = EventBus.handlers_for(Administration::Events::PoolKeyRemoved)

        expect(handlers).to include(Administration::Handlers::LogPoolKeyChange)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Market Data
  # ---------------------------------------------------------------------------
  describe "Market Data subscriptions" do
    describe "MarketData::Events::AssetPriceUpdated" do
      it "has alert evaluation, broadcast, price history, and trend score handlers" do
        handlers = EventBus.handlers_for(MarketData::Events::AssetPriceUpdated)

        expect(handlers).to include(Alerts::Handlers::EvaluateAlertsOnPriceUpdate)
        expect(handlers).to include(MarketData::Handlers::BroadcastPriceUpdate)
        expect(handlers).to include(MarketData::Handlers::RecordPriceHistory)
        expect(handlers).to include(MarketData::Handlers::RecalculateTrendScoreOnPriceUpdate)
      end
    end

    describe "MarketData::Events::AllGatewaysFailed" do
      it "has MarketData::Handlers::LogAllGatewaysFailure handler" do
        handlers = EventBus.handlers_for(MarketData::Events::AllGatewaysFailed)

        expect(handlers).to include(MarketData::Handlers::LogAllGatewaysFailure)
      end
    end

    describe "MarketData::Events::NewsSynced" do
      it "has MarketData::Handlers::LogNewsSync handler" do
        handlers = EventBus.handlers_for(MarketData::Events::NewsSynced)

        expect(handlers).to include(MarketData::Handlers::LogNewsSync)
      end
    end

    describe "MarketData::Events::EarningsSynced" do
      it "has MarketData::Handlers::LogEarningsSync handler" do
        handlers = EventBus.handlers_for(MarketData::Events::EarningsSynced)

        expect(handlers).to include(MarketData::Handlers::LogEarningsSync)
      end
    end

    describe "MarketData::Events::MarketIndicesUpdated" do
      it "has MarketData::Handlers::LogMarketIndicesUpdate handler" do
        handlers = EventBus.handlers_for(MarketData::Events::MarketIndicesUpdated)

        expect(handlers).to include(MarketData::Handlers::LogMarketIndicesUpdate)
      end
    end

    describe "MarketData::Events::FearGreedUpdated" do
      it "has log and sentiment alert evaluation handlers" do
        handlers = EventBus.handlers_for(MarketData::Events::FearGreedUpdated)

        expect(handlers).to include(MarketData::Handlers::LogFearGreedUpdate)
        expect(handlers).to include(Alerts::Handlers::EvaluateSentimentAlerts)
      end
    end

    describe "MarketData::Events::DividendsSynced" do
      it "has MarketData::Handlers::LogDividendsSync handler" do
        handlers = EventBus.handlers_for(MarketData::Events::DividendsSynced)

        expect(handlers).to include(MarketData::Handlers::LogDividendsSync)
      end
    end

    describe "MarketData::Events::CetesSynced" do
      it "has MarketData::Handlers::LogCetesSync handler" do
        handlers = EventBus.handlers_for(MarketData::Events::CetesSynced)

        expect(handlers).to include(MarketData::Handlers::LogCetesSync)
      end
    end

    describe "MarketData::Events::AssetFundamentalsUpdated" do
      it "has log and broadcast handlers" do
        handlers = EventBus.handlers_for(MarketData::Events::AssetFundamentalsUpdated)

        expect(handlers).to include(MarketData::Handlers::LogFundamentalsUpdate)
        expect(handlers).to include(MarketData::Handlers::BroadcastFundamentalsUpdate)
      end
    end

    describe "MarketData::Events::FinancialStatementsSynced" do
      it "has MarketData::Handlers::RecalculateFundamentalsOnStatementsSynced handler" do
        handlers = EventBus.handlers_for(MarketData::Events::FinancialStatementsSynced)

        expect(handlers).to include(MarketData::Handlers::RecalculateFundamentalsOnStatementsSynced)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Alerts
  # ---------------------------------------------------------------------------
  describe "Alerts subscriptions" do
    describe "Alerts::Events::AlertRuleTriggered" do
      it "has alert event creation and notification handlers" do
        handlers = EventBus.handlers_for(Alerts::Events::AlertRuleTriggered)

        expect(handlers).to include(Alerts::Handlers::CreateAlertEventOnTrigger)
        expect(handlers).to include(Alerts::Handlers::CreateNotificationOnAlert)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Notifications
  # ---------------------------------------------------------------------------
  describe "Notifications subscriptions" do
    describe "Notifications::Events::NotificationCreated" do
      it "has Notifications::Handlers::BroadcastNotification handler" do
        handlers = EventBus.handlers_for(Notifications::Events::NotificationCreated)

        expect(handlers).to include(Notifications::Handlers::BroadcastNotification)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Trading
  # ---------------------------------------------------------------------------
  describe "Trading subscriptions" do
    describe "Trading::Events::TradeExecuted" do
      it "has avg cost recalculation and trade activity log handlers" do
        handlers = EventBus.handlers_for(Trading::Events::TradeExecuted)

        expect(handlers).to include(Trading::Handlers::RecalculateAvgCostOnTrade)
        expect(handlers).to include(Trading::Handlers::LogTradeActivity)
      end
    end

    describe "Trading::Events::TradeUpdated" do
      it "has Trading::Handlers::LogTradeUpdate handler" do
        handlers = EventBus.handlers_for(Trading::Events::TradeUpdated)

        expect(handlers).to include(Trading::Handlers::LogTradeUpdate)
      end
    end

    describe "Trading::Events::TradeDeleted" do
      it "has Trading::Handlers::LogTradeDelete handler" do
        handlers = EventBus.handlers_for(Trading::Events::TradeDeleted)

        expect(handlers).to include(Trading::Handlers::LogTradeDelete)
      end
    end

    describe "Trading::Events::SplitDetected" do
      it "has Trading::Handlers::AdjustPositionsOnSplit handler" do
        handlers = EventBus.handlers_for(Trading::Events::SplitDetected)

        expect(handlers).to include(Trading::Handlers::AdjustPositionsOnSplit)
      end
    end
  end
end
