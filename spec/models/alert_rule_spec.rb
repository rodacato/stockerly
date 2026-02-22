require "rails_helper"

RSpec.describe AlertRule, type: :model do
  subject(:rule) { build(:alert_rule) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires asset_symbol" do
      rule.asset_symbol = nil
      expect(rule).not_to be_valid
    end

    it "requires threshold_value" do
      rule.threshold_value = nil
      expect(rule).not_to be_valid
    end

    it "requires numeric threshold_value" do
      rule.threshold_value = "abc"
      expect(rule).not_to be_valid
    end
  end

  describe "enums" do
    it "defines condition enum with 5 values" do
      expect(AlertRule.conditions.keys).to contain_exactly(
        "price_crosses_above", "price_crosses_below",
        "day_change_percent", "rsi_overbought", "rsi_oversold"
      )
    end

    it "defines status enum" do
      expect(AlertRule.statuses).to eq("active" => 0, "paused" => 1)
    end
  end

  describe "associations" do
    it "nullifies alert_events on destroy" do
      rule = create(:alert_rule)
      event = create(:alert_event, alert_rule: rule, user: rule.user)
      rule.destroy
      expect(event.reload.alert_rule_id).to be_nil
    end
  end
end
