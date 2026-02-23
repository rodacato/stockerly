require "rails_helper"

RSpec.describe AlertEvaluator do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, current_price: 150.0) }

  describe ".evaluate" do
    it "returns empty array when no rules are triggered" do
      rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 200.0)

      triggered = AlertEvaluator.evaluate([ rule ], asset, 160.0)
      expect(triggered).to be_empty
    end

    it "returns triggered rules only" do
      rule1 = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 155.0)
      rule2 = create(:alert_rule, user: user, asset_symbol: "OTHER", condition: :price_crosses_above, threshold_value: 200.0)

      triggered = AlertEvaluator.evaluate([ rule1, rule2 ], asset, 160.0)
      expect(triggered).to eq([ rule1 ])
    end

    context "price_crosses_above" do
      it "triggers when price crosses above threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 155.0)

        triggered = AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to include(rule)
      end

      it "does not trigger when price stays below threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 200.0)

        triggered = AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to be_empty
      end
    end

    context "price_crosses_below" do
      it "triggers when price crosses below threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_below, threshold_value: 145.0)

        triggered = AlertEvaluator.evaluate([ rule ], asset, 140.0)
        expect(triggered).to include(rule)
      end
    end

    context "day_change_percent" do
      it "triggers when absolute day change exceeds threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 5.0)

        # 150 -> 160 = 6.67% change
        triggered = AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to include(rule)
      end

      it "does not trigger when change is below threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 10.0)

        # 150 -> 155 = 3.33% change
        triggered = AlertEvaluator.evaluate([ rule ], asset, 155.0)
        expect(triggered).to be_empty
      end

      it "handles zero current price gracefully" do
        asset_zero = create(:asset, symbol: "ZERO", current_price: 0)
        rule = create(:alert_rule, user: user, asset_symbol: "ZERO", condition: :day_change_percent, threshold_value: 5.0)

        triggered = AlertEvaluator.evaluate([ rule ], asset_zero, 10.0)
        expect(triggered).to be_empty
      end
    end

    context "rsi_overbought" do
      it "triggers when trend score is at or above threshold" do
        create(:trend_score, asset: asset, score: 80, calculated_at: Time.current)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :rsi_overbought, threshold_value: 70.0)

        triggered = AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to include(rule)
      end
    end

    context "rsi_oversold" do
      it "triggers when trend score is at or below threshold" do
        create(:trend_score, asset: asset, score: 20, calculated_at: Time.current)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :rsi_oversold, threshold_value: 30.0)

        triggered = AlertEvaluator.evaluate([ rule ], asset, 140.0)
        expect(triggered).to include(rule)
      end
    end
  end
end
