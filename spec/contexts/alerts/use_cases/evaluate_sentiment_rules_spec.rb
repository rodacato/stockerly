require "rails_helper"

RSpec.describe Alerts::UseCases::EvaluateSentimentRules do
  subject(:use_case) { described_class.new }

  let(:user) { create(:user) }

  describe "#call" do
    it "returns triggered rules and publishes Alerts::Events::AlertRuleTriggered" do
      rule = create(:alert_rule, user: user, asset_symbol: "FG_CRYPTO",
                    condition: :sentiment_above, threshold_value: 70.0, status: :active)
      allow(EventBus).to receive(:publish)

      result = use_case.call(index_type: "crypto", value: 75)

      expect(result).to be_success
      expect(result.value!).to include(rule)
      expect(EventBus).to have_received(:publish).with(an_instance_of(Alerts::Events::AlertRuleTriggered))
      expect(rule.reload.status).to eq("paused")
    end

    it "returns empty array when no rules match" do
      create(:alert_rule, user: user, asset_symbol: "FG_CRYPTO",
             condition: :sentiment_above, threshold_value: 80.0, status: :active)

      result = use_case.call(index_type: "crypto", value: 50)

      expect(result).to be_success
      expect(result.value!).to be_empty
    end
  end
end
