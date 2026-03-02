require "rails_helper"

RSpec.describe "Event Subscription Wiring" do
  # Reload subscriptions (cleared by EventBus.clear! in each test)
  before { load Rails.root.join("config/initializers/event_subscriptions.rb") }

  describe "AssetPriceUpdated" do
    it "has Alerts::EvaluateAlertsOnPriceUpdate and BroadcastPriceUpdate handlers" do
      handlers = EventBus.handlers_for(MarketData::AssetPriceUpdated)

      expect(handlers).to include(Alerts::EvaluateAlertsOnPriceUpdate)
      expect(handlers).to include(MarketData::BroadcastPriceUpdate)
    end
  end

  describe "Alerts::AlertRuleTriggered" do
    it "has Alerts::CreateAlertEventOnTrigger and Alerts::CreateNotificationOnAlert handlers" do
      handlers = EventBus.handlers_for(Alerts::AlertRuleTriggered)

      expect(handlers).to include(Alerts::CreateAlertEventOnTrigger)
      expect(handlers).to include(Alerts::CreateNotificationOnAlert)
    end
  end

  describe "Notifications::NotificationCreated" do
    it "has Notifications::BroadcastNotification handler" do
      handlers = EventBus.handlers_for(Notifications::NotificationCreated)

      expect(handlers).to include(Notifications::BroadcastNotification)
    end
  end

  describe "Trading::TradeExecuted" do
    it "has Trading::RecalculateAvgCostOnTrade and Trading::LogTradeActivity handlers" do
      handlers = EventBus.handlers_for(Trading::TradeExecuted)

      expect(handlers).to include(Trading::RecalculateAvgCostOnTrade)
      expect(handlers).to include(Trading::LogTradeActivity)
    end
  end

  describe "Identity::UserRegistered" do
    it "has portfolio, alert prefs, and welcome email handlers" do
      handlers = EventBus.handlers_for(Identity::UserRegistered)

      expect(handlers).to include(Identity::CreatePortfolioOnRegistration)
      expect(handlers).to include(Identity::CreateAlertPreferencesOnRegistration)
      expect(handlers).to include(Identity::SendWelcomeEmailOnRegistration)
    end
  end

  describe "Identity::UserSuspended" do
    it "has audit log and suspension email handlers" do
      handlers = EventBus.handlers_for(Identity::UserSuspended)

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
