require "rails_helper"

RSpec.describe Alerts::UseCases::UpdateRule do
  let(:user) { create(:user) }
  let!(:rule) { create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 150.0) }
  let(:valid_params) { { asset_symbol: "MSFT", condition: "price_crosses_below", threshold_value: 400.0 } }

  describe ".call" do
    it "updates the alert rule and returns Success" do
      result = described_class.call(user: user, rule_id: rule.id, params: valid_params)

      expect(result).to be_success
      updated = result.value!
      expect(updated.asset_symbol).to eq("MSFT")
      expect(updated.condition).to eq("price_crosses_below")
      expect(updated.threshold_value).to eq(400.0)
    end

    it "uppercases the asset symbol" do
      result = described_class.call(user: user, rule_id: rule.id, params: valid_params.merge(asset_symbol: "msft"))
      expect(result.value!.asset_symbol).to eq("MSFT")
    end

    it "returns Failure(:not_found) when rule does not exist" do
      result = described_class.call(user: user, rule_id: 999999, params: valid_params)
      expect(result).to be_failure
      expect(result.failure[0]).to eq(:not_found)
    end

    it "returns Failure(:not_found) when rule belongs to another user" do
      other_user = create(:user, email: "other@example.com")
      result = described_class.call(user: other_user, rule_id: rule.id, params: valid_params)
      expect(result).to be_failure
      expect(result.failure[0]).to eq(:not_found)
    end

    it "returns Failure(:validation) when params are invalid" do
      result = described_class.call(user: user, rule_id: rule.id, params: { asset_symbol: "", condition: "invalid", threshold_value: nil })
      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end
  end
end
