require "rails_helper"

RSpec.describe MarketData::Queries::UpcomingEarnings do
  let(:asset) { create(:asset, :stock, symbol: "AAPL") }

  describe ".within" do
    it "returns an event reporting today" do
      event = create(:earnings_event, asset: asset, report_date: Date.current)

      expect(described_class.within(days: 3)).to contain_exactly(event)
    end

    it "returns an event on the last day of the window" do
      event = create(:earnings_event, asset: asset, report_date: 3.days.from_now.to_date)

      expect(described_class.within(days: 3)).to contain_exactly(event)
    end

    it "excludes an event past the window" do
      create(:earnings_event, asset: asset, report_date: 4.days.from_now.to_date)

      expect(described_class.within(days: 3)).to be_empty
    end

    it "excludes an event whose date has already passed" do
      create(:earnings_event, asset: asset, report_date: 1.day.ago.to_date)

      expect(described_class.within(days: 3)).to be_empty
    end

    it "counts the window from the given date rather than today" do
      event = create(:earnings_event, asset: asset, report_date: 10.days.from_now.to_date)

      expect(described_class.within(days: 3, from: 8.days.from_now.to_date)).to contain_exactly(event)
    end
  end
end
