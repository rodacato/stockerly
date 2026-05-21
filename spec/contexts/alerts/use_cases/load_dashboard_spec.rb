require "rails_helper"

RSpec.describe Alerts::UseCases::LoadDashboard do
  let(:user) { create(:user) }

  describe ".call" do
    it "returns Success with rules, events, preference, counts and triggered_today" do
      create(:alert_rule, user: user, asset_symbol: "AAPL", status: :active)
      create(:alert_rule, user: user, asset_symbol: "NVDA", status: :paused)
      create(:alert_preference, user: user)

      result = described_class.call(user: user)

      expect(result).to be_success
      data = result.value!
      expect(data[:rules].count).to eq(1) # filter defaults to active
      expect(data[:counts]).to eq(active: 1, paused: 1, all: 2)
      expect(data[:filter]).to eq("active")
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
      expect(data[:counts]).to eq(active: 0, paused: 0, all: 0)
    end

    it "filters by 'paused' when requested" do
      create(:alert_rule, user: user, asset_symbol: "AAPL", status: :active)
      create(:alert_rule, user: user, asset_symbol: "NVDA", status: :paused)

      result = described_class.call(user: user, filter: "paused")
      expect(result.value![:rules].count).to eq(1)
      expect(result.value![:rules].first.asset_symbol).to eq("NVDA")
    end

    it "filters by 'all' when requested" do
      create(:alert_rule, user: user, asset_symbol: "AAPL", status: :active)
      create(:alert_rule, user: user, asset_symbol: "NVDA", status: :paused)

      result = described_class.call(user: user, filter: "all")
      expect(result.value![:rules].count).to eq(2)
    end

    it "falls back to 'active' on unknown filter" do
      create(:alert_rule, user: user, asset_symbol: "AAPL", status: :active)
      create(:alert_rule, user: user, asset_symbol: "NVDA", status: :paused)

      result = described_class.call(user: user, filter: "garbage")
      expect(result.value![:filter]).to eq("active")
      expect(result.value![:rules].count).to eq(1)
    end
  end
end
