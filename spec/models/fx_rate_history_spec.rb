require "rails_helper"

RSpec.describe FxRateHistory do
  describe ".rate_on" do
    it "returns the rate published on that date" do
      described_class.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 12), rate: 17.0)

      expect(described_class.rate_on(base: "USD", quote: "MXN", date: Date.new(2026, 5, 12))).to eq(17.0)
    end

    # A trade executed on a Saturday has no fix of its own: Banxico does not
    # publish on weekends or Mexican holidays. Friday's rate is the honest
    # answer; today's is not.
    it "falls back to the most recent rate before the date" do
      described_class.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 8), rate: 17.0)
      described_class.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 15), rate: 18.0)

      expect(described_class.rate_on(base: "USD", quote: "MXN", date: Date.new(2026, 5, 10))).to eq(17.0)
    end

    it "never reaches forward for a rate that did not exist yet" do
      described_class.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 15), rate: 18.0)

      expect(described_class.rate_on(base: "USD", quote: "MXN", date: Date.new(2026, 5, 10))).to be_nil
    end

    it "inverts the pair when only the reverse direction was stored" do
      described_class.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 12), rate: 20.0)

      rate = described_class.rate_on(base: "MXN", quote: "USD", date: Date.new(2026, 5, 12))

      expect(rate).to be_within(0.0001).of(0.05)
    end

    it "is 1 for the same currency without touching the table" do
      expect(described_class).not_to receive(:for_pair)

      expect(described_class.rate_on(base: "MXN", quote: "MXN", date: Date.current)).to eq(1)
    end
  end

  describe ".record" do
    it "updates the rate for a date instead of duplicating it" do
      described_class.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 12), rate: 17.0)
      described_class.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 12), rate: 17.5, source: "banxico_fix")

      expect(described_class.for_pair("USD", "MXN").count).to eq(1)
      expect(described_class.last.rate).to eq(17.5)
      expect(described_class.last.source).to eq("banxico_fix")
    end
  end
end
