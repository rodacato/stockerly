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
      expect(notification.title).to eq("AAPL cruzó USD 200.00 al alza")
      expect(notification.notification_type).to eq("alert_triggered")
    end

    it "reports the trigger price with its currency and does not restate the title" do
      described_class.call(
        alert_rule_id: rule.id,
        user_id: user.id,
        asset_symbol: "AAPL",
        triggered_price: "200.14"
      )

      notification = Notification.last
      expect(notification.body).to include("USD 200.14")
      expect(notification.body).not_to include(notification.title)
    end
  end
end
