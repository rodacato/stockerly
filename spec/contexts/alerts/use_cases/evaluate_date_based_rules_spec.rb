require "rails_helper"

RSpec.describe Alerts::UseCases::EvaluateDateBasedRules do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, symbol: "AAPL", current_price: 200.0) }

  describe ".call" do
    it "publishes AlertRuleTriggered for each matching rule" do
      rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :dividend_ex_date, threshold_value: 0, window_days: 7)
      create(:dividend, asset: asset, ex_date: 7.days.from_now.to_date, amount_per_share: 0.5)

      published = []
      EventBus.subscribe(Alerts::Events::AlertRuleTriggered, ->(event) { published << event })

      result = described_class.call

      expect(result).to be_success
      expect(published.size).to eq(1)
      expect(published.first.alert_rule_id).to eq(rule.id)
      expect(published.first.asset_symbol).to eq(rule.asset_symbol)
    end

    it "publishes nothing when no rules match" do
      create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :dividend_ex_date, threshold_value: 0, window_days: 3)
      create(:dividend, asset: asset, ex_date: 30.days.from_now.to_date, amount_per_share: 0.5)

      published = []
      EventBus.subscribe(Alerts::Events::AlertRuleTriggered, ->(event) { published << event })

      result = described_class.call
      expect(result).to be_success
      expect(published).to be_empty
    end

    it "ignores paused rules" do
      create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :dividend_ex_date, threshold_value: 0, window_days: 7, status: :paused)
      create(:dividend, asset: asset, ex_date: 7.days.from_now.to_date, amount_per_share: 0.5)

      published = []
      EventBus.subscribe(Alerts::Events::AlertRuleTriggered, ->(event) { published << event })

      described_class.call
      expect(published).to be_empty
    end

    it "ignores price-based rules" do
      create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 100.0)

      published = []
      EventBus.subscribe(Alerts::Events::AlertRuleTriggered, ->(event) { published << event })

      described_class.call
      expect(published).to be_empty
    end
  end
end
