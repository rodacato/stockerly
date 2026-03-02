require "rails_helper"

RSpec.describe Alerts::UseCases::ToggleRule do
  let(:user) { create(:user) }

  describe ".call" do
    it "toggles active rule to paused" do
      rule = create(:alert_rule, user: user, status: :active)
      result = described_class.call(user: user, rule_id: rule.id)

      expect(result).to be_success
      expect(result.value!.reload).to be_paused
    end

    it "toggles paused rule to active" do
      rule = create(:alert_rule, user: user, status: :paused)
      result = described_class.call(user: user, rule_id: rule.id)

      expect(result).to be_success
      expect(result.value!.reload).to be_active
    end

    it "returns Failure when rule not found" do
      result = described_class.call(user: user, rule_id: 0)
      expect(result).to be_failure
      expect(result.failure[0]).to eq(:not_found)
    end

    it "cannot toggle another user's rule" do
      other = create(:user, email: "other@example.com")
      rule = create(:alert_rule, user: other)
      result = described_class.call(user: user, rule_id: rule.id)
      expect(result).to be_failure
    end
  end
end
