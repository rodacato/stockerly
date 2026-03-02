require "rails_helper"

RSpec.describe Alerts::AlertEvaluator do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, current_price: 150.0) }

  describe ".evaluate" do
    it "returns empty array when no rules are triggered" do
      rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 200.0)

      triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset, 160.0)
      expect(triggered).to be_empty
    end

    it "returns triggered rules only" do
      rule1 = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 155.0)
      rule2 = create(:alert_rule, user: user, asset_symbol: "OTHER", condition: :price_crosses_above, threshold_value: 200.0)

      triggered = Alerts::AlertEvaluator.evaluate([ rule1, rule2 ], asset, 160.0)
      expect(triggered).to eq([ rule1 ])
    end

    context "price_crosses_above" do
      it "triggers when price crosses above threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 155.0)

        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to include(rule)
      end

      it "does not trigger when price stays below threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 200.0)

        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to be_empty
      end
    end

    context "price_crosses_below" do
      it "triggers when price crosses below threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_below, threshold_value: 145.0)

        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset, 140.0)
        expect(triggered).to include(rule)
      end
    end

    context "day_change_percent" do
      it "triggers when absolute day change exceeds threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 5.0)

        # 150 -> 160 = 6.67% change
        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to include(rule)
      end

      it "does not trigger when change is below threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 10.0)

        # 150 -> 155 = 3.33% change
        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset, 155.0)
        expect(triggered).to be_empty
      end

      it "handles zero current price gracefully" do
        asset_zero = create(:asset, symbol: "ZERO", current_price: 0)
        rule = create(:alert_rule, user: user, asset_symbol: "ZERO", condition: :day_change_percent, threshold_value: 5.0)

        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset_zero, 10.0)
        expect(triggered).to be_empty
      end
    end

    context "rsi_overbought" do
      it "triggers when trend score is at or above threshold" do
        create(:trend_score, asset: asset, score: 80, calculated_at: Time.current)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :rsi_overbought, threshold_value: 70.0)

        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to include(rule)
      end
    end

    context "rsi_oversold" do
      it "triggers when trend score is at or below threshold" do
        create(:trend_score, asset: asset, score: 20, calculated_at: Time.current)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :rsi_oversold, threshold_value: 30.0)

        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset, 140.0)
        expect(triggered).to include(rule)
      end
    end

    context "volume_spike" do
      it "triggers when volume exceeds threshold × average volume" do
        asset_vol = create(:asset, symbol: "VOL", current_price: 100.0, volume: 500_000)
        5.times do |i|
          create(:asset_price_history, asset: asset_vol, date: (i + 1).days.ago.to_date, close: 100, volume: 100_000)
        end
        rule = create(:alert_rule, user: user, asset_symbol: "VOL", condition: :volume_spike, threshold_value: 3.0)

        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset_vol, 100.0)
        expect(triggered).to include(rule)
      end

      it "does not trigger when volume is below threshold × average" do
        asset_vol = create(:asset, symbol: "VOL2", current_price: 100.0, volume: 150_000)
        5.times do |i|
          create(:asset_price_history, asset: asset_vol, date: (i + 1).days.ago.to_date, close: 100, volume: 100_000)
        end
        rule = create(:alert_rule, user: user, asset_symbol: "VOL2", condition: :volume_spike, threshold_value: 3.0)

        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset_vol, 100.0)
        expect(triggered).to be_empty
      end
    end

    context "cooldown filtering" do
      it "skips rules within cooldown period" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol,
                       condition: :price_crosses_above, threshold_value: 155.0,
                       last_triggered_at: 10.minutes.ago, cooldown_minutes: 60)

        triggered = Alerts::AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to be_empty
      end
    end
  end

  describe ".evaluate_sentiment" do
    context "sentiment_above" do
      it "triggers when F&G value equals threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: "FG_CRYPTO", condition: :sentiment_above, threshold_value: 70.0)
        triggered = Alerts::AlertEvaluator.evaluate_sentiment([ rule ], 70)
        expect(triggered).to include(rule)
      end

      it "triggers when F&G value exceeds threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: "FG_CRYPTO", condition: :sentiment_above, threshold_value: 70.0)
        triggered = Alerts::AlertEvaluator.evaluate_sentiment([ rule ], 85)
        expect(triggered).to include(rule)
      end

      it "does not trigger when F&G value is below threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: "FG_CRYPTO", condition: :sentiment_above, threshold_value: 70.0)
        triggered = Alerts::AlertEvaluator.evaluate_sentiment([ rule ], 60)
        expect(triggered).to be_empty
      end
    end

    context "sentiment_below" do
      it "triggers when F&G value equals threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: "FG_STOCKS", condition: :sentiment_below, threshold_value: 30.0)
        triggered = Alerts::AlertEvaluator.evaluate_sentiment([ rule ], 30)
        expect(triggered).to include(rule)
      end

      it "triggers when F&G value is below threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: "FG_STOCKS", condition: :sentiment_below, threshold_value: 30.0)
        triggered = Alerts::AlertEvaluator.evaluate_sentiment([ rule ], 15)
        expect(triggered).to include(rule)
      end

      it "does not trigger when F&G value is above threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: "FG_STOCKS", condition: :sentiment_below, threshold_value: 30.0)
        triggered = Alerts::AlertEvaluator.evaluate_sentiment([ rule ], 45)
        expect(triggered).to be_empty
      end
    end
  end
end
