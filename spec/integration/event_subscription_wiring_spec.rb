require "rails_helper"

RSpec.describe "Event Subscription Wiring" do
  # Reload subscriptions (cleared by EventBus.clear! in each test)
  before { load Rails.root.join("config/initializers/event_subscriptions.rb") }

  describe "AssetPriceUpdated" do
    it "has Alerts::Handlers::EvaluateAlertsOnPriceUpdate and BroadcastPriceUpdate handlers" do
      handlers = EventBus.handlers_for(MarketData::Events::AssetPriceUpdated)

      expect(handlers).to include(Alerts::Handlers::EvaluateAlertsOnPriceUpdate)
      expect(handlers).to include(MarketData::Handlers::BroadcastPriceUpdate)
    end
  end

  describe "Alerts::Events::AlertRuleTriggered" do
    it "has Alerts::Handlers::CreateAlertEventOnTrigger and Alerts::Handlers::CreateNotificationOnAlert handlers" do
      handlers = EventBus.handlers_for(Alerts::Events::AlertRuleTriggered)

      expect(handlers).to include(Alerts::Handlers::CreateAlertEventOnTrigger)
      expect(handlers).to include(Alerts::Handlers::CreateNotificationOnAlert)
    end
  end

  describe "Notifications::Events::NotificationCreated" do
    it "has Notifications::Handlers::BroadcastNotification handler" do
      handlers = EventBus.handlers_for(Notifications::Events::NotificationCreated)

      expect(handlers).to include(Notifications::Handlers::BroadcastNotification)
    end
  end

  describe "Trading::Events::TradeExecuted" do
    it "has Trading::Handlers::RecalculateAvgCostOnTrade and Trading::Handlers::LogTradeActivity handlers" do
      handlers = EventBus.handlers_for(Trading::Events::TradeExecuted)

      expect(handlers).to include(Trading::Handlers::RecalculateAvgCostOnTrade)
      expect(handlers).to include(Trading::Handlers::LogTradeActivity)
    end
  end

  describe "Identity::Events::UserRegistered" do
    it "has portfolio, alert prefs, and welcome email handlers" do
      handlers = EventBus.handlers_for(Identity::Events::UserRegistered)

      expect(handlers).to include(Identity::Handlers::CreatePortfolioOnRegistration)
      expect(handlers).to include(Identity::Handlers::CreateAlertPreferencesOnRegistration)
      expect(handlers).to include(Identity::Handlers::SendWelcomeEmailOnRegistration)
    end
  end

  describe "Identity::Events::UserSuspended" do
    it "has audit log and suspension email handlers" do
      handlers = EventBus.handlers_for(Identity::Events::UserSuspended)

      expect(handlers).to include(Administration::CreateAuditLogOnSuspension)
      expect(handlers).to include(Administration::SendSuspensionEmail)
    end
  end

  describe "Administration::IntegrationConnected" do
    it "has Administration::LogIntegrationConnected handler" do
      handlers = EventBus.handlers_for(Administration::IntegrationConnected)

      expect(handlers).to include(Administration::LogIntegrationConnected)
    end
  end
end
