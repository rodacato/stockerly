require "rails_helper"

RSpec.describe Alerts::Domain::AlertEvaluator do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, current_price: 150.0) }

  describe ".evaluate" do
    it "returns empty array when no rules are triggered" do
      rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 200.0)

      triggered = Alerts::Domain::AlertEvaluator.evaluate([ rule ], asset, 160.0)
      expect(triggered).to be_empty
    end

    it "returns triggered rules only" do
      rule1 = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 155.0)
      rule2 = create(:alert_rule, user: user, asset_symbol: "OTHER", condition: :price_crosses_above, threshold_value: 200.0)

      triggered = Alerts::Domain::AlertEvaluator.evaluate([ rule1, rule2 ], asset, 160.0)
      expect(triggered).to eq([ rule1 ])
    end

    context "price_crosses_above" do
      it "triggers when price crosses above threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 155.0)

        triggered = Alerts::Domain::AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to include(rule)
      end

      it "does not trigger when price stays below threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_above, threshold_value: 200.0)

        triggered = Alerts::Domain::AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to be_empty
      end
    end

    context "price_crosses_below" do
      it "triggers when price crosses below threshold" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :price_crosses_below, threshold_value: 145.0)

        triggered = Alerts::Domain::AlertEvaluator.evaluate([ rule ], asset, 140.0)
        expect(triggered).to include(rule)
      end
    end

    # #455: the condition used to measure the move between two consecutive
    # syncs under a name that promises a day. It now reads the same day change
    # every screen shows (ADR-021), computed from the previous daily close.
    context "day_change_percent" do
      def close_on(a, date, close)
        create(:asset_price_history, asset: a, date: date, close: close)
      end

      it "triggers on a day move past the threshold" do
        close_on(asset, 1.day.ago.to_date, 150.0)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 5.0)

        # previous close 150 -> arriving 160 = 6.67% on the day
        expect(described_class.evaluate([ rule ], asset, 160.0)).to include(rule)
      end

      it "does not trigger on a day move below the threshold" do
        close_on(asset, 1.day.ago.to_date, 150.0)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 10.0)

        expect(described_class.evaluate([ rule ], asset, 155.0)).to be_empty
      end

      # The defect, pinned: an asset that oscillates travels far sync to sync
      # while the day change stays flat. Under the old measure each 4% swing
      # fired; the day never moved.
      it "does not trigger on consecutive swings whose day change stays flat" do
        close_on(asset, 1.day.ago.to_date, 150.0)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 3.0)

        asset.update!(current_price: 156.0)
        expect(described_class.evaluate([ rule ], asset, 150.5)).to be_empty
      end

      # The other half of the defect: a calm 4% drift over a session never
      # produced a single 4% step, so it never fired.
      it "triggers on a slow drift the old sync-to-sync measure would have missed" do
        close_on(asset, 1.day.ago.to_date, 150.0)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 3.0)

        asset.update!(current_price: 155.9)
        expect(described_class.evaluate([ rule ], asset, 156.0)).to include(rule)
      end

      # Unknown is not a move.
      it "does not trigger when the asset has no earlier close" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 1.0)

        expect(described_class.evaluate([ rule ], asset, 999.0)).to be_empty
      end

      it "does not fall back to the previous sync when the day change is unknown" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 5.0)

        asset.update!(current_price: 100.0)
        expect(described_class.evaluate([ rule ], asset, 200.0)).to be_empty
      end

      it "ignores today's row, which still carries the previous sync at evaluation time" do
        close_on(asset, 1.day.ago.to_date, 150.0)
        close_on(asset, Date.current, 155.0)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 5.0)

        # Against today's stale row it is 3.2%; against yesterday's close, 6.67%.
        expect(described_class.evaluate([ rule ], asset, 160.0)).to include(rule)
      end

      it "returns nothing when the previous close is zero" do
        close_on(asset, 1.day.ago.to_date, 0.0)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent, threshold_value: 5.0)

        expect(described_class.evaluate([ rule ], asset, 10.0)).to be_empty
      end

      # A level, not an event: it stays past the threshold all session.
      # Anchored to the start of today, not to a relative offset: `3.hours.ago`
      # lands on yesterday when the suite runs before 03:00, and the condition
      # under test is exactly "did it already fire today".
      it "fires once a day rather than every cooldown window" do
        close_on(asset, 1.day.ago.to_date, 150.0)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent,
                      threshold_value: 5.0, last_triggered_at: Time.current.beginning_of_day)

        expect(described_class.evaluate([ rule ], asset, 160.0)).to be_empty
      end

      it "fires again once the day has turned" do
        close_on(asset, 1.day.ago.to_date, 150.0)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :day_change_percent,
                      threshold_value: 5.0, last_triggered_at: 1.day.ago.end_of_day - 1.hour)

        expect(described_class.evaluate([ rule ], asset, 160.0)).to include(rule)
      end
    end

    context "rsi_overbought" do
      it "triggers when trend score is at or above threshold" do
        create(:trend_score, asset: asset, score: 80, calculated_at: Time.current)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :rsi_overbought, threshold_value: 70.0)

        triggered = Alerts::Domain::AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to include(rule)
      end
    end

    context "rsi_oversold" do
      it "triggers when trend score is at or below threshold" do
        create(:trend_score, asset: asset, score: 20, calculated_at: Time.current)
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :rsi_oversold, threshold_value: 30.0)

        triggered = Alerts::Domain::AlertEvaluator.evaluate([ rule ], asset, 140.0)
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

        triggered = Alerts::Domain::AlertEvaluator.evaluate([ rule ], asset_vol, 100.0)
        expect(triggered).to include(rule)
      end

      it "does not trigger when volume is below threshold × average" do
        asset_vol = create(:asset, symbol: "VOL2", current_price: 100.0, volume: 150_000)
        5.times do |i|
          create(:asset_price_history, asset: asset_vol, date: (i + 1).days.ago.to_date, close: 100, volume: 100_000)
        end
        rule = create(:alert_rule, user: user, asset_symbol: "VOL2", condition: :volume_spike, threshold_value: 3.0)

        triggered = Alerts::Domain::AlertEvaluator.evaluate([ rule ], asset_vol, 100.0)
        expect(triggered).to be_empty
      end
    end

    context "cooldown filtering" do
      it "skips rules within cooldown period" do
        rule = create(:alert_rule, user: user, asset_symbol: asset.symbol,
                       condition: :price_crosses_above, threshold_value: 155.0,
                       last_triggered_at: 10.minutes.ago, cooldown_minutes: 60)

        triggered = Alerts::Domain::AlertEvaluator.evaluate([ rule ], asset, 160.0)
        expect(triggered).to be_empty
      end
    end
  end
end
