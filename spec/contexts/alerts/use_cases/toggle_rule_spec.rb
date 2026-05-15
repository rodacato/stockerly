require "rails_helper"

RSpec.describe Alerts::UseCases::ToggleRule do
  let(:user) { create(:user) }

  describe ".call" do
    it "toggles an active rule to paused" do
      rule = create(:alert_rule, user: user, status: :active)
      result = described_class.call(user: user, rule_id: rule.id)

      expect(result.reload).to be_paused
    end

    it "toggles a paused rule to active" do
      rule = create(:alert_rule, user: user, status: :paused)
      result = described_class.call(user: user, rule_id: rule.id)

      expect(result.reload).to be_active
    end

    it "raises ActiveRecord::RecordNotFound for an unknown rule id" do
      expect {
        described_class.call(user: user, rule_id: 0)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "cannot toggle another user's rule (scoped to user.alert_rules)" do
      other = create(:user, email: "other@example.com")
      rule  = create(:alert_rule, user: other)

      expect {
        described_class.call(user: user, rule_id: rule.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
