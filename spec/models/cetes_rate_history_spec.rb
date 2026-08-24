require "rails_helper"

RSpec.describe CetesRateHistory do
  describe ".rate_on" do
    # Auctions are weekly, so an exact-date lookup would miss six days in seven.
    it "returns the most recent auction on or before the date" do
      described_class.record(term: "28", date: Date.new(2026, 1, 8), rate: 10.15)
      described_class.record(term: "28", date: Date.new(2026, 1, 15), rate: 10.05)

      expect(described_class.rate_on(term: "28", date: Date.new(2026, 1, 12))).to eq(10.15)
      expect(described_class.rate_on(term: "28", date: Date.new(2026, 1, 15))).to eq(10.05)
    end

    it "returns nil before the first auction it holds" do
      described_class.record(term: "28", date: Date.new(2026, 1, 8), rate: 10.15)

      expect(described_class.rate_on(term: "28", date: Date.new(2025, 12, 1))).to be_nil
    end

    it "does not cross terms" do
      described_class.record(term: "91", date: Date.new(2026, 1, 8), rate: 10.50)

      expect(described_class.rate_on(term: "28", date: Date.new(2026, 1, 12))).to be_nil
    end
  end

  describe "validations" do
    it "rejects a term Banxico does not auction" do
      row = described_class.new(term: "45", auction_date: Date.current, yield_rate: 10)
      expect(row).not_to be_valid
    end

    it "rejects a non-positive yield" do
      row = described_class.new(term: "28", auction_date: Date.current, yield_rate: 0)
      expect(row).not_to be_valid
    end

    it "keeps one row per term and date" do
      described_class.record(term: "28", date: Date.new(2026, 1, 8), rate: 10.15)
      duplicate = described_class.new(term: "28", auction_date: Date.new(2026, 1, 8), yield_rate: 9.0)

      expect(duplicate).not_to be_valid
    end
  end
end
