require "rails_helper"

RSpec.describe EarningsEvent, type: :model do
  subject(:event) { build(:earnings_event) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires report_date" do
      event.report_date = nil
      expect(event).not_to be_valid
    end

    it "requires timing" do
      event.timing = nil
      expect(event).not_to be_valid
    end

    it "requires unique report_date per asset" do
      asset = create(:asset)
      create(:earnings_event, asset: asset, report_date: "2026-03-15")
      dup = build(:earnings_event, asset: asset, report_date: "2026-03-15")
      expect(dup).not_to be_valid
    end
  end

  describe "enums" do
    it "defines timing enum" do
      expect(EarningsEvent.timings).to eq(
        "before_market_open" => 0, "after_market_close" => 1
      )
    end
  end

  describe "scopes" do
    let(:asset) { create(:asset) }

    it ".for_month returns events for a given month" do
      march = create(:earnings_event, asset: asset, report_date: "2026-03-15")
      april = create(:earnings_event, asset: create(:asset), report_date: "2026-04-10")
      expect(EarningsEvent.for_month(Date.new(2026, 3, 1))).to contain_exactly(march)
    end

    it ".upcoming returns future events ordered by date" do
      past = create(:earnings_event, asset: asset, report_date: 1.month.ago)
      future = create(:earnings_event, asset: create(:asset), report_date: 1.month.from_now)
      expect(EarningsEvent.upcoming).to contain_exactly(future)
    end

    it ".reported returns events with actual_eps" do
      reported = create(:earnings_event, asset: asset, report_date: 1.month.ago, actual_eps: 3.0)
      _pending = create(:earnings_event, asset: create(:asset), report_date: 1.month.from_now)
      expect(EarningsEvent.reported).to contain_exactly(reported)
    end

    it ".upcoming_window returns events in the next N days" do
      in_window = create(:earnings_event, asset: asset, report_date: 3.days.from_now.to_date)
      far       = create(:earnings_event, asset: create(:asset), report_date: 30.days.from_now.to_date)
      expect(EarningsEvent.upcoming_window(7)).to contain_exactly(in_window)
      expect(EarningsEvent.upcoming_window(31)).to contain_exactly(in_window, far)
    end

    it ".recent_window returns events from the previous N days (excluding today)" do
      recent = create(:earnings_event, asset: asset, report_date: 3.days.ago.to_date, actual_eps: 1.0)
      today  = create(:earnings_event, asset: create(:asset), report_date: Date.current)
      expect(EarningsEvent.recent_window(7)).to contain_exactly(recent)
      expect(EarningsEvent.recent_window(7)).not_to include(today)
    end

    it ".for_market filters by Asset.exchange" do
      bmv_asset = create(:asset, :stock, exchange: "BMV")
      bmv_event = create(:earnings_event, asset: bmv_asset, report_date: 3.days.from_now.to_date)
      _us_event = create(:earnings_event, asset: create(:asset, :stock, exchange: "NASDAQ"), report_date: 3.days.from_now.to_date)
      expect(EarningsEvent.for_market("BMV")).to contain_exactly(bmv_event)
    end

    it ".for_market acts as no-op for unknown values" do
      bmv_asset = create(:asset, :stock, exchange: "BMV")
      bmv_event = create(:earnings_event, asset: bmv_asset, report_date: 3.days.from_now.to_date)
      us_event  = create(:earnings_event, asset: create(:asset, :stock, exchange: "NASDAQ"), report_date: 3.days.from_now.to_date)
      expect(EarningsEvent.for_market("todos")).to contain_exactly(bmv_event, us_event)
    end
  end

  describe "#beat_miss" do
    it "returns :beat when actual >= estimated" do
      event = build(:earnings_event, estimated_eps: 2.50, actual_eps: 2.80)
      expect(event.beat_miss).to eq(:beat)
    end

    it "returns :beat when actual equals estimated" do
      event = build(:earnings_event, estimated_eps: 2.50, actual_eps: 2.50)
      expect(event.beat_miss).to eq(:beat)
    end

    it "returns :miss when actual < estimated" do
      event = build(:earnings_event, estimated_eps: 2.50, actual_eps: 2.10)
      expect(event.beat_miss).to eq(:miss)
    end

    it "returns nil when actual_eps is nil" do
      event = build(:earnings_event, estimated_eps: 2.50, actual_eps: nil)
      expect(event.beat_miss).to be_nil
    end
  end

  describe "#eps_surprise_percent" do
    it "calculates positive surprise percentage" do
      event = build(:earnings_event, estimated_eps: 2.00, actual_eps: 2.20)
      expect(event.eps_surprise_percent).to eq(10.0)
    end

    it "calculates negative surprise percentage" do
      event = build(:earnings_event, estimated_eps: 2.00, actual_eps: 1.80)
      expect(event.eps_surprise_percent).to eq(-10.0)
    end

    it "returns nil when data is missing" do
      event = build(:earnings_event, estimated_eps: 2.00, actual_eps: nil)
      expect(event.eps_surprise_percent).to be_nil
    end
  end
end
