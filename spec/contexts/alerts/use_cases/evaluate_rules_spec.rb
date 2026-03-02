require "rails_helper"

RSpec.describe Alerts::EvaluateRules do
  subject(:use_case) { described_class.new }

  let(:user) { create(:user) }
  let(:asset) { create(:asset, symbol: "AAPL", current_price: 150.0) }

  describe "#call" do
    context "when asset does not exist" do
      it "returns failure" do
        result = use_case.call(asset_id: -1, new_price: "200.0")

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:not_found)
      end
    end

    context "when no rules match" do
      before do
        create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 300, status: :active)
      end

      it "returns success with empty array" do
        result = use_case.call(asset_id: asset.id, new_price: "155.0")

        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end

    context "when a rule triggers" do
      let!(:rule) do
        create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 155, status: :active)
      end

      it "returns the triggered rules" do
        result = use_case.call(asset_id: asset.id, new_price: "160.0")

        expect(result).to be_success
        expect(result.value!).to include(rule)
      end

      it "publishes Alerts::AlertRuleTriggered event" do
        allow(EventBus).to receive(:publish)

        use_case.call(asset_id: asset.id, new_price: "160.0")

        expect(EventBus).to have_received(:publish).with(
          an_instance_of(Alerts::AlertRuleTriggered)
        )
      end
    end

    context "when rule is paused" do
      before do
        create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 155, status: :paused)
      end

      it "ignores paused rules" do
        result = use_case.call(asset_id: asset.id, new_price: "160.0")

        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end
  end
end
