require "rails_helper"

RSpec.describe Alerts::UseCases::CreateRule do
  let(:user) { create(:user) }

  describe ".call" do
    let(:valid_params) { { asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 200.0 } }

    it "creates an alert rule and returns Success" do
      result = described_class.call(user: user, params: valid_params)

      expect(result).to be_success
      rule = result.value!
      expect(rule.asset_symbol).to eq("AAPL")
      expect(rule.condition).to eq("price_crosses_above")
      expect(rule.threshold_value).to eq(200.0)
      expect(rule).to be_active
    end

    it "uppercases the asset symbol" do
      result = described_class.call(user: user, params: valid_params.merge(asset_symbol: "aapl"))
      expect(result.value!.asset_symbol).to eq("AAPL")
    end

    it "returns Failure when asset_symbol is missing" do
      result = described_class.call(user: user, params: valid_params.merge(asset_symbol: ""))
      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure when condition is invalid" do
      result = described_class.call(user: user, params: valid_params.merge(condition: "invalid"))
      expect(result).to be_failure
    end

    it "returns Failure when threshold is missing" do
      result = described_class.call(user: user, params: valid_params.merge(threshold_value: nil))
      expect(result).to be_failure
    end
  end
end
