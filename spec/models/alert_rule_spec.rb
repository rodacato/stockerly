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
    it "defines condition enum with 8 values including volume_spike" do
      expect(AlertRule.conditions.keys).to contain_exactly(
        "price_crosses_above", "price_crosses_below",
        "day_change_percent", "rsi_overbought", "rsi_oversold",
        "sentiment_above", "sentiment_below", "volume_spike"
      )
    end

    it "assigns integer values for sentiment and volume conditions" do
      expect(AlertRule.conditions["sentiment_above"]).to eq(5)
      expect(AlertRule.conditions["sentiment_below"]).to eq(6)
      expect(AlertRule.conditions["volume_spike"]).to eq(7)
    end

    it "defines status enum" do
      expect(AlertRule.statuses).to eq("active" => 0, "paused" => 1)
    end
  end

  describe "#cooled_down?" do
    it "returns true when last_triggered_at is nil" do
      rule = build(:alert_rule, last_triggered_at: nil, cooldown_minutes: 60)
      expect(rule.cooled_down?).to be true
    end

    it "returns true when cooldown period has elapsed" do
      rule = build(:alert_rule, last_triggered_at: 2.hours.ago, cooldown_minutes: 60)
      expect(rule.cooled_down?).to be true
    end

    it "returns false when within cooldown period" do
      rule = build(:alert_rule, last_triggered_at: 10.minutes.ago, cooldown_minutes: 60)
      expect(rule.cooled_down?).to be false
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
