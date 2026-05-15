require "rails_helper"

RSpec.describe MarketData::Queries::CurrentFearGreed do
  describe ".call" do
    it "returns nil readings and empty history when no data exists" do
      result = described_class.call
      expect(result[:crypto]).to be_nil
      expect(result[:stocks]).to be_nil
      expect(result[:crypto_history]).to be_empty
      expect(result[:stocks_history]).to be_empty
    end

    it "returns the latest reading for crypto and stocks" do
      create(:fear_greed_reading, :crypto, fetched_at: 2.hours.ago, value: 30)
      create(:fear_greed_reading, :crypto, fetched_at: 1.hour.ago, value: 45)
      create(:fear_greed_reading, :stocks, fetched_at: 1.hour.ago, value: 70)

      result = described_class.call
      expect(result[:crypto].value).to eq(45)
      expect(result[:stocks].value).to eq(70)
    end

    it "returns history as ordered [fetched_at, value] tuples ASC" do
      create(:fear_greed_reading, :crypto, value: 30, fetched_at: 2.days.ago)
      create(:fear_greed_reading, :crypto, value: 45, fetched_at: 1.day.ago)

      result = described_class.call
      expect(result[:crypto_history].size).to eq(2)
      expect(result[:crypto_history].first.last).to eq(30)
      expect(result[:crypto_history].last.last).to eq(45)
    end
  end
end
