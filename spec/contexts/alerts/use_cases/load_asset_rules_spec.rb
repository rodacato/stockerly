require "rails_helper"

RSpec.describe Alerts::UseCases::LoadAssetRules do
  let!(:user) { create(:user) }

  describe ".call" do
    it "returns only the rules bound to that symbol" do
      mine = create(:alert_rule, user: user, asset_symbol: "NVDA")
      create(:alert_rule, user: user, asset_symbol: "AAPL")

      expect(described_class.call(user: user, symbol: "NVDA")).to eq([ mine ])
    end

    it "returns the newest rules first, capped at three" do
      oldest = create(:alert_rule, user: user, asset_symbol: "NVDA", created_at: 4.days.ago)
      four = create(:alert_rule, user: user, asset_symbol: "NVDA", created_at: 3.days.ago)
      three = create(:alert_rule, user: user, asset_symbol: "NVDA", created_at: 2.days.ago)
      newest = create(:alert_rule, user: user, asset_symbol: "NVDA", created_at: 1.day.ago)

      result = described_class.call(user: user, symbol: "NVDA")

      expect(result).to eq([ newest, three, four ])
      expect(result).not_to include(oldest)
    end

    it "does not return another user's rules for the same symbol" do
      create(:alert_rule, user: create(:user), asset_symbol: "NVDA")

      expect(described_class.call(user: user, symbol: "NVDA")).to be_empty
    end
  end
end
