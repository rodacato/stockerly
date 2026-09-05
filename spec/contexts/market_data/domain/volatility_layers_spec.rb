require "rails_helper"

RSpec.describe MarketData::Domain::VolatilityLayers do
  describe ".entries" do
    it "steps down by one ATR a layer" do
      layers = described_class.entries(price: 100.0, atr: 4.0)

      expect(layers.map(&:price)).to eq([ 96.0, 92.0, 88.0 ])
      expect(layers.map(&:atr_distance)).to eq([ 1.0, 2.0, 3.0 ])
    end

    # The whole claim of the family: the same decision lands in different
    # places because the assets move differently, not because anyone chose
    # different round numbers.
    it "puts the same decision at different prices for differently moving assets" do
      volatile = described_class.entries(price: 100.0, atr: 7.5)
      calm = described_class.entries(price: 100.0, atr: 0.8)

      expect(volatile.first.price).to eq(92.5)
      expect(calm.first.price).to eq(99.2)
    end

    # DoD: no layers rather than layers at zero spacing. Three levels stacked
    # on the current price would look like a reading and contain nothing.
    it "returns nothing when there is no ATR to space by" do
      expect(described_class.entries(price: 100.0, atr: nil)).to be_empty
      expect(described_class.entries(price: 100.0, atr: 0)).to be_empty
    end

    it "returns nothing without a price to step down from" do
      expect(described_class.entries(price: nil, atr: 4.0)).to be_empty
    end

    it "drops a layer that would fall through zero rather than pricing a negative" do
      layers = described_class.entries(price: 10.0, atr: 4.0)

      expect(layers.map(&:price)).to eq([ 6.0, 2.0 ])
    end

    it "takes a count and a spacing" do
      layers = described_class.entries(price: 100.0, atr: 2.0, count: 2, spacing: 0.5)

      expect(layers.map(&:price)).to eq([ 99.0, 98.0 ])
    end
  end

  describe ".trailing_exit" do
    # Chandelier Exit (Chuck LeBeau): highest high less three ATR. Computed
    # from the definition rather than from this implementation — 120 - 3 * 5.
    it "trails the high by three ATR" do
      exit_level = described_class.trailing_exit(highest_high: 120.0, atr: 5.0)

      expect(exit_level.price).to eq(105.0)
      expect(exit_level.atr_distance).to eq(3.0)
    end

    it "is not the mirror of the entry ladder — it hangs off the high, not off spot" do
      entries = described_class.entries(price: 100.0, atr: 5.0)
      exit_level = described_class.trailing_exit(highest_high: 120.0, atr: 5.0)

      expect(exit_level.price).to be > entries.first.price
    end

    it "is absent rather than zero when the reading carries no ATR" do
      expect(described_class.trailing_exit(highest_high: 120.0, atr: nil)).to be_nil
    end

    it "is absent when no high has closed yet" do
      expect(described_class.trailing_exit(highest_high: nil, atr: 5.0)).to be_nil
    end

    it "is absent rather than negative when three ATR exceed the high" do
      expect(described_class.trailing_exit(highest_high: 10.0, atr: 5.0)).to be_nil
    end
  end
end
