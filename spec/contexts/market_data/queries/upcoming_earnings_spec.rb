require "rails_helper"

RSpec.describe MarketData::Queries::UpcomingEarnings do
  let(:asset) { create(:asset, :stock, symbol: "AAPL") }

  describe "an asset the provider moved to another date" do
    def event(on:, touched:)
      create(:earnings_event, asset: asset, report_date: on).tap { |e| e.update_columns(updated_at: touched) }
    end

    it "reads the row touched last and drops the superseded estimates" do
      event(on: 2.days.from_now.to_date, touched: 30.days.ago)
      current = event(on: 5.days.from_now.to_date, touched: 1.day.ago)
      event(on: 6.days.from_now.to_date, touched: 20.days.ago)

      expect(described_class.within(days: 7)).to contain_exactly(current)
    end

    it "does not show an old estimate inside the window when the current date is past it" do
      event(on: 3.days.from_now.to_date, touched: 30.days.ago)
      event(on: 20.days.from_now.to_date, touched: 1.day.ago)

      expect(described_class.within(days: 7)).to be_empty
    end

    it "does not fall back to an old row when the current one already reported" do
      event(on: 4.days.from_now.to_date, touched: 30.days.ago)
      event(on: 1.day.ago.to_date, touched: 1.day.ago)

      expect(described_class.within(days: 7)).to be_empty
    end

    it "names one next date per asset, however far off" do
      event(on: 10.days.from_now.to_date, touched: 30.days.ago)
      current = event(on: 40.days.from_now.to_date, touched: 1.day.ago)

      expect(described_class.next_for(asset: asset)).to eq(current)
    end

    it "has no next date when there is none" do
      expect(described_class.next_for(asset: asset)).to be_nil
    end
  end

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
