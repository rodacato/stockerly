require "rails_helper"

RSpec.describe Alerts::CreateAlertEventOnTrigger do
  describe ".call" do
    let(:user) { create(:user) }
    let(:rule) { create(:alert_rule, user: user, asset_symbol: "AAPL") }

    it "creates an AlertEvent" do
      expect {
        described_class.call(
          alert_rule_id: rule.id,
          user_id: user.id,
          asset_symbol: "AAPL",
          triggered_price: "200.0"
        )
      }.to change(AlertEvent, :count).by(1)

      event = AlertEvent.last
      expect(event.alert_rule).to eq(rule)
      expect(event.asset_symbol).to eq("AAPL")
      expect(event.event_status).to eq("triggered")
    end
  end
end
