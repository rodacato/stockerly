require "rails_helper"

RSpec.describe Alerts::Domain::DateBasedAlertEvaluator do
  let(:user) { create(:user) }
  let(:asset) { create(:asset, symbol: "AAPL", current_price: 200.0) }

  describe ".evaluate" do
    it "returns empty when no rules match" do
      create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :dividend_ex_date, threshold_value: 0, window_days: 7)

      results = described_class.evaluate([])
      expect(results).to be_empty
    end

    it "triggers dividend_ex_date rule on the exact day the ex-date is window_days away" do
      rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :dividend_ex_date, threshold_value: 0, window_days: 7)
      create(:dividend, asset: asset, ex_date: 7.days.from_now.to_date, amount_per_share: 0.25)

      results = described_class.evaluate([ rule ])
      expect(results.size).to eq(1)
      expect(results.first.rule).to eq(rule)
      expect(results.first.context[:days_until]).to eq(7)
    end

    it "does NOT trigger between the boundary day and the ex-date (single-shot, no daily spam)" do
      rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :dividend_ex_date, threshold_value: 0, window_days: 7)
      create(:dividend, asset: asset, ex_date: 3.days.from_now.to_date, amount_per_share: 0.25)

      results = described_class.evaluate([ rule ])
      expect(results).to be_empty
    end

    it "does NOT trigger when ex-date is past the window boundary" do
      rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :dividend_ex_date, threshold_value: 0, window_days: 3)
      create(:dividend, asset: asset, ex_date: 10.days.from_now.to_date, amount_per_share: 0.25)

      results = described_class.evaluate([ rule ])
      expect(results).to be_empty
    end

    it "does NOT trigger when the ex-date is in the past" do
      rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :dividend_ex_date, threshold_value: 0, window_days: 7)
      create(:dividend, asset: asset, ex_date: 2.days.ago.to_date, amount_per_share: 0.25)

      results = described_class.evaluate([ rule ])
      expect(results).to be_empty
    end

    it "respects cooldown" do
      rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :dividend_ex_date, threshold_value: 0, window_days: 7,
                                  last_triggered_at: 10.minutes.ago, cooldown_minutes: 60)
      create(:dividend, asset: asset, ex_date: 7.days.from_now.to_date, amount_per_share: 0.25)

      results = described_class.evaluate([ rule ])
      expect(results).to be_empty
    end

    it "defaults to a 7-day window when window_days is nil" do
      rule = create(:alert_rule, user: user, asset_symbol: asset.symbol, condition: :dividend_ex_date, threshold_value: 0, window_days: nil)
      create(:dividend, asset: asset, ex_date: 7.days.from_now.to_date, amount_per_share: 0.25)

      results = described_class.evaluate([ rule ])
      expect(results.size).to eq(1)
    end

    it "looks up the asset by normalized uppercase symbol" do
      rule = create(:alert_rule, user: user, asset_symbol: "aapl", condition: :dividend_ex_date, threshold_value: 0, window_days: 7)
      create(:dividend, asset: asset, ex_date: 7.days.from_now.to_date, amount_per_share: 0.25)

      results = described_class.evaluate([ rule ])
      expect(results.size).to eq(1)
    end
  end
end
