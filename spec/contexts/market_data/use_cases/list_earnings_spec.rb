require "rails_helper"

RSpec.describe MarketData::ListEarnings do
  let(:user) { create(:user) }
  let(:apple) { create(:asset, symbol: "AAPL") }
  let(:tesla) { create(:asset, symbol: "TSLA") }
  let(:date) { Date.new(2024, 10, 15) }

  let!(:apple_event) { create(:earnings_event, asset: apple, report_date: Date.new(2024, 10, 24)) }
  let!(:tesla_event) { create(:earnings_event, asset: tesla, report_date: Date.new(2024, 10, 18)) }

  before do
    create(:watchlist_item, user: user, asset: apple)
  end

  describe "#call" do
    it "returns all events for the given month" do
      result = described_class.call(user: user, date: date)
      expect(result).to be_success
      data = result.value!
      expect(data[:events]).to include(apple_event, tesla_event)
      expect(data[:date]).to eq(date)
    end

    it "filters events by watchlist when requested" do
      result = described_class.call(user: user, date: date, filter: "watchlist")
      data = result.value!
      expect(data[:events]).to include(apple_event)
      expect(data[:events]).not_to include(tesla_event)
    end

    it "always returns watchlist_events" do
      result = described_class.call(user: user, date: date)
      data = result.value!
      expect(data[:watchlist_events]).to include(apple_event)
      expect(data[:watchlist_events]).not_to include(tesla_event)
    end

    it "returns empty when no events in month" do
      result = described_class.call(user: user, date: Date.new(2025, 6, 1))
      data = result.value!
      expect(data[:events]).to be_empty
    end
  end
end
