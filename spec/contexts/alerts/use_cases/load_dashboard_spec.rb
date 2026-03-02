require "rails_helper"

RSpec.describe Alerts::LoadDashboard do
  let(:user) { create(:user) }

  describe ".call" do
    it "returns Success with rules, events, preference, and triggered_today count" do
      create(:alert_rule, user: user, asset_symbol: "AAPL")
      create(:alert_preference, user: user)

      result = described_class.call(user: user)

      expect(result).to be_success
      data = result.value!
      expect(data[:rules].count).to eq(1)
      expect(data).to have_key(:events)
      expect(data).to have_key(:preference)
      expect(data).to have_key(:triggered_today)
    end

    it "returns empty collections for user with no alerts" do
      result = described_class.call(user: user)

      expect(result).to be_success
      data = result.value!
      expect(data[:rules]).to be_empty
      expect(data[:triggered_today]).to eq(0)
    end
  end
end
