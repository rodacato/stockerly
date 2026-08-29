require "rails_helper"

# Normalisation only. Which closes reach it is
# MarketData::Queries::PriceSeries.recent_closes, specced beside it.
RSpec.describe SparklineHelper do
  describe "#sparkline_heights" do
    it "normalises a rising series across the full 0-100 range" do
      heights = helper.sparkline_heights([ 100, 110, 120, 130 ])

      expect(heights).to eq([ 0, 33, 67, 100 ])
    end

    it "centres a flat series rather than dividing by a zero range" do
      expect(helper.sparkline_heights([ 50.0, 50.0, 50.0 ])).to all(eq(50))
    end

    it "keeps the series' own direction, since it normalises rather than sorts" do
      expect(helper.sparkline_heights([ 130, 120, 110, 100 ])).to eq([ 100, 67, 33, 0 ])
    end

    it "returns nil when there is no shape to draw" do
      expect(helper.sparkline_heights([])).to be_nil
      expect(helper.sparkline_heights([ 100 ])).to be_nil
      expect(helper.sparkline_heights(nil)).to be_nil
    end
  end
end
