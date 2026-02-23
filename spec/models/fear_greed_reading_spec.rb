require "rails_helper"

RSpec.describe FearGreedReading, type: :model do
  subject(:reading) { build(:fear_greed_reading) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires index_type" do
      reading.index_type = nil
      expect(reading).not_to be_valid
    end

    it "requires index_type to be crypto or stocks" do
      reading.index_type = "forex"
      expect(reading).not_to be_valid
    end

    it "requires value between 0 and 100" do
      reading.value = 101
      expect(reading).not_to be_valid
    end

    it "requires classification" do
      reading.classification = nil
      expect(reading).not_to be_valid
    end

    it "requires source" do
      reading.source = nil
      expect(reading).not_to be_valid
    end

    it "requires fetched_at" do
      reading.fetched_at = nil
      expect(reading).not_to be_valid
    end
  end

  describe "scopes" do
    let!(:crypto_reading) { create(:fear_greed_reading, :crypto, fetched_at: 1.hour.ago) }
    let!(:stocks_reading) { create(:fear_greed_reading, :stocks, fetched_at: 2.hours.ago) }

    it ".crypto returns only crypto readings" do
      expect(described_class.crypto).to contain_exactly(crypto_reading)
    end

    it ".stocks returns only stocks readings" do
      expect(described_class.stocks).to contain_exactly(stocks_reading)
    end

    it ".latest_crypto returns most recent crypto reading" do
      expect(described_class.latest_crypto).to eq(crypto_reading)
    end

    it ".latest_stocks returns most recent stocks reading" do
      expect(described_class.latest_stocks).to eq(stocks_reading)
    end
  end

  describe "#stale?" do
    it "returns true when fetched_at is older than 25 hours" do
      reading.fetched_at = 26.hours.ago
      expect(reading).to be_stale
    end

    it "returns false when fetched_at is recent" do
      reading.fetched_at = 1.hour.ago
      expect(reading).not_to be_stale
    end
  end

  describe ".classify" do
    it "returns Extreme Fear for 0-24" do
      expect(described_class.classify(15)).to eq("Extreme Fear")
    end

    it "returns Fear for 25-44" do
      expect(described_class.classify(30)).to eq("Fear")
    end

    it "returns Neutral for 45-55" do
      expect(described_class.classify(50)).to eq("Neutral")
    end

    it "returns Greed for 56-74" do
      expect(described_class.classify(65)).to eq("Greed")
    end

    it "returns Extreme Greed for 75-100" do
      expect(described_class.classify(90)).to eq("Extreme Greed")
    end
  end
end
