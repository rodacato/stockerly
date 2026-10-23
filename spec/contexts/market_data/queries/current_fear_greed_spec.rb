require "rails_helper"

RSpec.describe MarketData::Queries::CurrentFearGreed do
  describe ".call" do
    it "returns nil readings and empty history when no data exists" do
      result = described_class.call
      expect(result[:crypto]).to be_nil
      expect(result[:crypto_history]).to be_empty
    end

    it "returns the latest crypto reading" do
      create(:fear_greed_reading, :crypto, fetched_at: 2.hours.ago, value: 30)
      create(:fear_greed_reading, :crypto, fetched_at: 1.hour.ago, value: 45)

      result = described_class.call
      expect(result[:crypto].value).to eq(45)
    end

    it "returns history as ordered [fetched_at, value] tuples ASC" do
      create(:fear_greed_reading, :crypto, value: 30, fetched_at: 2.days.ago)
      create(:fear_greed_reading, :crypto, value: 45, fetched_at: 1.day.ago)

      result = described_class.call
      expect(result[:crypto_history].size).to eq(2)
      expect(result[:crypto_history].first.last).to eq(30)
      expect(result[:crypto_history].last.last).to eq(45)
    end

    # F3.1: the newest thirty, oldest first; not the first thirty ever stored.
    it "keeps the latest readings once there are more than the window holds" do
      40.times { |n| create(:fear_greed_reading, :crypto, value: n, fetched_at: (40 - n).days.ago) }

      history = described_class.call[:crypto_history]

      expect(history.size).to eq(30)
      expect(history.map(&:last).values_at(0, -1)).to eq([ 10, 39 ])
    end
  end
end
