require "rails_helper"

RSpec.describe MarketData::Domain::DayChange do
  describe ".from_closes" do
    it "reads the move from the previous close to the current one" do
      expect(described_class.from_closes([ 100, 102 ])).to eq(2)
    end

    it "reads a fall as a negative move" do
      expect(described_class.from_closes([ 200, 190 ])).to eq(-5)
    end

    it "ignores everything before the last two closes" do
      expect(described_class.from_closes([ 10, 50, 100, 102 ])).to eq(2)
    end

    # Equities do not trade every day and crypto does, so "previous" is the
    # previous row — never yesterday's date.
    it "compares against the previous row whatever date it carries" do
      asset = create(:asset, :stock)
      create(:asset_price_history, asset: asset, date: 4.days.ago.to_date, close: 100)
      create(:asset_price_history, asset: asset, date: Date.current, close: 105)

      closes = MarketData::Queries::PriceSeries.recent_closes([ asset ])[asset.id]

      expect(described_class.from_closes(closes)).to eq(5)
    end

    # A newly tracked asset has nothing to compare against. Reporting 0 would
    # say it was flat, which is a different claim from not knowing.
    it "has no reading with only one close" do
      expect(described_class.from_closes([ 100 ])).to be_nil
    end

    it "has no reading with no closes at all" do
      expect(described_class.from_closes(nil)).to be_nil
      expect(described_class.from_closes([])).to be_nil
    end

    it "does not divide by a zero previous close" do
      expect(described_class.from_closes([ 0, 10 ])).to be_nil
    end

    it "reads two identical closes as flat, which is a reading" do
      expect(described_class.from_closes([ 100, 100 ])).to eq(0)
    end

    it "keeps decimal precision rather than rounding to the integer" do
      expect(described_class.from_closes([ 68.9655, 70 ]).round(2)).to eq(1.5)
    end
  end

  describe ".by_asset" do
    it "maps each asset's closes to its own reading" do
      expect(described_class.by_asset(1 => [ 100, 110 ], 2 => [ 50 ]))
        .to eq(1 => 10, 2 => nil)
    end
  end
end
