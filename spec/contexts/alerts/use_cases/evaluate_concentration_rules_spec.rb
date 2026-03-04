require "rails_helper"

RSpec.describe Alerts::UseCases::EvaluateConcentrationRules do
  let(:user) { create(:user) }

  describe ".call" do
    it "triggers rule when HHI exceeds threshold" do
      rule = create(:alert_rule,
        user: user,
        asset_symbol: "PORTFOLIO",
        condition: :concentration_risk,
        threshold_value: 2500,
        status: :active)

      result = described_class.call(user: user, hhi: 3000)

      expect(result).to be_success
      expect(result.value!).to include(rule)
      expect(rule.reload.last_triggered_at).not_to be_nil
    end

    it "does not trigger when HHI is below threshold" do
      rule = create(:alert_rule,
        user: user,
        asset_symbol: "PORTFOLIO",
        condition: :concentration_risk,
        threshold_value: 2500,
        status: :active)

      result = described_class.call(user: user, hhi: 1000)

      expect(result).to be_success
      expect(result.value!).to be_empty
    end

    it "respects cooldown period" do
      rule = create(:alert_rule,
        user: user,
        asset_symbol: "PORTFOLIO",
        condition: :concentration_risk,
        threshold_value: 2500,
        status: :active,
        last_triggered_at: 10.minutes.ago,
        cooldown_minutes: 60)

      result = described_class.call(user: user, hhi: 3000)

      expect(result).to be_success
      expect(result.value!).to be_empty
    end
  end
end
