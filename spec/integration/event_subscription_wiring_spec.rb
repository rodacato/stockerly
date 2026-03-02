require "rails_helper"

RSpec.describe "Event Subscription Wiring" do
  # Reload subscriptions (cleared by EventBus.clear! in each test)
  before { load Rails.root.join("config/initializers/event_subscriptions.rb") }

  describe "AssetPriceUpdated" do
    it "has EvaluateAlertsOnPriceUpdate and BroadcastPriceUpdate handlers" do
      handlers = EventBus.handlers_for(AssetPriceUpdated)

      expect(handlers).to include(EvaluateAlertsOnPriceUpdate)
      expect(handlers).to include(BroadcastPriceUpdate)
    end
  end

  describe "AlertRuleTriggered" do
    it "has CreateAlertEventOnTrigger and CreateNotificationOnAlert handlers" do
      handlers = EventBus.handlers_for(AlertRuleTriggered)

      expect(handlers).to include(CreateAlertEventOnTrigger)
      expect(handlers).to include(CreateNotificationOnAlert)
    end
  end

  describe "NotificationCreated" do
    it "has BroadcastNotification handler" do
      handlers = EventBus.handlers_for(NotificationCreated)

      expect(handlers).to include(BroadcastNotification)
    end
  end

  describe "TradeExecuted" do
    it "has RecalculateAvgCostOnTrade and LogTradeActivity handlers" do
      handlers = EventBus.handlers_for(TradeExecuted)

      expect(handlers).to include(RecalculateAvgCostOnTrade)
      expect(handlers).to include(LogTradeActivity)
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

      expect(handlers).to include(CreateAuditLogOnSuspension)
      expect(handlers).to include(SendSuspensionEmail)
    end
  end

  describe "IntegrationConnected" do
    it "has LogIntegrationConnected handler" do
      handlers = EventBus.handlers_for(IntegrationConnected)

      expect(handlers).to include(LogIntegrationConnected)
    end
  end
end
