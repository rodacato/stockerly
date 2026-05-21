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

    describe "bmv_holiday" do
      let(:rule) { create(:alert_rule, :marketwide, user: user, condition: :bmv_holiday, window_days: 3) }

      it "triggers on the boundary day when a BMV holiday is exactly window_days ahead" do
        target = 3.days.from_now.to_date
        MarketHoliday.create!(market: :BMV, date: target, name: "Festivo de prueba")

        results = described_class.evaluate([ rule ])

        expect(results.size).to eq(1)
        expect(results.first.event_date).to eq(target)
        expect(results.first.context[:holiday_name]).to eq("Festivo de prueba")
        expect(results.first.context[:days_until]).to eq(3)
      end

      it "does NOT trigger between boundary day and the holiday (single-shot)" do
        MarketHoliday.create!(market: :BMV, date: 2.days.from_now.to_date, name: "Festivo de prueba")

        results = described_class.evaluate([ rule ])
        expect(results).to be_empty
      end

      it "does NOT trigger for a Banxico-only holiday when the rule is BMV-scoped" do
        target = 3.days.from_now.to_date
        MarketHoliday.create!(market: :Banxico, date: target, name: "Solo Banxico")

        results = described_class.evaluate([ rule ])
        expect(results).to be_empty
      end
    end

    describe "cete_auction" do
      let(:rule) { create(:alert_rule, :marketwide, user: user, condition: :cete_auction, window_days: 3) }

      it "triggers when the next non-holiday Tuesday is exactly window_days ahead" do
        # Find a Tuesday 3 days from "today" we can pivot to.
        today = Date.new(2026, 5, 16) # Saturday
        # Tuesday 3 days later = 2026-05-19. Not on Banxico holiday list.

        results = described_class.evaluate([ rule ], today: today)

        expect(results.size).to eq(1)
        expect(results.first.event_date).to eq(Date.new(2026, 5, 19))
      end

      it "skips a Tuesday that falls on a Banxico holiday" do
        today = Date.new(2026, 1, 30) # Friday; Tuesday +4 days = 2026-02-03 (not holiday)
        # Actually let's use a Tuesday that IS a holiday: 2026-02-02 (Día de la Constitución is Mon)
        # Closest tuesday holiday on our seed list... none obvious. Inject one inline.
        MarketHoliday.create!(market: :Banxico, date: Date.new(2026, 6, 30), name: "Inyectado para test") # 2026-06-30 is Tuesday

        # rule.window_days = 3; today = 2026-06-27 (Sat); +3 = 2026-06-30 (Tuesday holiday → skip)
        results = described_class.evaluate([ rule ], today: Date.new(2026, 6, 27))

        expect(results).to be_empty
      end

      it "does NOT trigger on a Tuesday that isn't window_days ahead" do
        today = Date.new(2026, 5, 16)
        results = described_class.evaluate([ create(:alert_rule, :marketwide, user: user, condition: :cete_auction, window_days: 7) ], today: today)

        # window_days=7 from a Saturday → 2026-05-23 (Saturday). Not a Tuesday.
        expect(results).to be_empty
      end
    end
  end

  describe ".next_cete_auction_date" do
    it "returns `from` itself when it is a non-holiday Tuesday" do
      expect(described_class.next_cete_auction_date(from: Date.new(2026, 5, 19))).to eq(Date.new(2026, 5, 19))
    end

    it "advances to the next Tuesday when `from` is not a Tuesday" do
      # 2026-05-16 is Saturday → next Tuesday is 2026-05-19
      expect(described_class.next_cete_auction_date(from: Date.new(2026, 5, 16))).to eq(Date.new(2026, 5, 19))
    end

    it "skips a Tuesday that lands on a Banxico holiday" do
      MarketHoliday.create!(market: :Banxico, date: Date.new(2026, 6, 30), name: "Test holiday")
      # 2026-06-30 is Tuesday → skip → next is 2026-07-07
      expect(described_class.next_cete_auction_date(from: Date.new(2026, 6, 30))).to eq(Date.new(2026, 7, 7))
    end
  end
end
