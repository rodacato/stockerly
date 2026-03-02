require "rails_helper"

RSpec.describe Alerts::UseCases::DestroyRule do
  let(:user) { create(:user) }

  describe ".call" do
    it "destroys the alert rule" do
      rule = create(:alert_rule, user: user)
      result = described_class.call(user: user, rule_id: rule.id)

      expect(result).to be_success
      expect(AlertRule.exists?(rule.id)).to be false
    end

    it "returns Failure when rule not found" do
      result = described_class.call(user: user, rule_id: 0)
      expect(result).to be_failure
    end
  end
end
