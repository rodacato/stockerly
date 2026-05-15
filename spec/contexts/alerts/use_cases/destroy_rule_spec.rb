require "rails_helper"

RSpec.describe Alerts::UseCases::DestroyRule do
  let(:user) { create(:user) }

  describe ".call" do
    it "destroys the alert rule" do
      rule = create(:alert_rule, user: user)

      expect {
        described_class.call(user: user, rule_id: rule.id)
      }.to change(AlertRule, :count).by(-1)
    end

    it "returns the destroyed (frozen) rule for caller inspection" do
      rule = create(:alert_rule, user: user)
      result = described_class.call(user: user, rule_id: rule.id)

      expect(result).to be_destroyed
    end

    it "raises ActiveRecord::RecordNotFound for an unknown rule id" do
      expect {
        described_class.call(user: user, rule_id: 0)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
