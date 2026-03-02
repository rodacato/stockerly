require "rails_helper"

RSpec.describe Alerts::Handlers::CreateNotificationOnAlert do
  describe ".async?" do
    it { expect(described_class.async?).to be true }
  end

  describe ".call" do
    let(:user) { create(:user) }
    let(:rule) { create(:alert_rule, user: user, asset_symbol: "AAPL") }

    it "creates a notification via use case" do
      expect {
        described_class.call(
          alert_rule_id: rule.id,
          user_id: user.id,
          asset_symbol: "AAPL",
          triggered_price: "200.0"
        )
      }.to change(Notification, :count).by(1)

      notification = Notification.last
      expect(notification.title).to include("AAPL")
      expect(notification.notification_type).to eq("alert_triggered")
    end
  end
end
