require "rails_helper"

RSpec.describe FxRateHistory do
  describe ".rate_on" do
    it "returns the rate published on that date" do
      described_class.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 12), rate: 17.0)

      expect(described_class.rate_on(base: "USD", quote: "MXN", date: Date.new(2026, 5, 12))).to eq(17.0)
    end

    # A safety net, not the normal path: the settlement series has a row for
    # every date, so this only fires for a gap the sync has not filled.
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

  describe ".record_all" do
    let(:source) { MarketData::Gateways::BanxicoGateway::FIX_SOURCE_ID }

    def rows(*pairs)
      pairs.map do |date, rate|
        { base_currency: "USD", quote_currency: "MXN", rate_date: date, rate: rate, source: source }
      end
    end

    it "inserts a whole series in one statement" do
      inserted = described_class.record_all(rows([ Date.new(2026, 5, 11), 17.0 ], [ Date.new(2026, 5, 12), 17.2 ]))

      expect(inserted).to eq(2)
      expect(described_class.for_pair("USD", "MXN").pluck(:rate_date, :rate))
        .to contain_exactly([ Date.new(2026, 5, 11), 17.0 ], [ Date.new(2026, 5, 12), 17.2 ])
    end

    # What makes the backfill safe to re-run, and what lets it overwrite the
    # determination-dated rows already in the table without deleting anything.
    it "corrects an existing date rather than duplicating it" do
      described_class.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 12), rate: 17.0, source: "banxico_fix")

      described_class.record_all(rows([ Date.new(2026, 5, 12), 17.4948 ]))

      expect(described_class.count).to eq(1)
      expect(described_class.first).to have_attributes(rate: 17.4948, source: source)
    end

    it "does nothing on an empty batch" do
      expect { described_class.record_all([]) }.not_to change(described_class, :count)
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
