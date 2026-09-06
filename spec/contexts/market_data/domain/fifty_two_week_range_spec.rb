require "rails_helper"

RSpec.describe MarketData::Domain::FiftyTwoWeekRange do
  def reading(price, low: 100, high: 200) = described_class.for(price: price, low: low, high: high)

  describe ".for" do
    it "places the price proportionally between the bounds" do
      expect(reading(150).position).to eq(0.5)
      expect(reading(175).position).to eq(0.75)
    end

    it "reports the distance to whichever bound is nearer" do
      near_high = reading(190)
      expect(near_high.zone).to eq(:high)
      expect(near_high.distance).to eq(5.0)

      near_low = reading(110)
      expect(near_low.zone).to eq(:low)
      expect(near_low.distance).to eq(10.0)
    end

    it "says the price is above the high rather than claiming it is near it" do
      result = reading(220)

      expect(result.zone).to eq(:above_high)
      expect(result.distance).to eq(10.0)
      expect(result.position).to eq(1)
    end

    it "says the price is below the low rather than claiming it is near it" do
      result = reading(80)

      expect(result.zone).to eq(:below_low)
      expect(result.distance).to eq(20.0)
      expect(result.position).to eq(0)
    end

    it "returns nil rather than a range when a bound is missing" do
      expect(described_class.for(price: 150, low: nil, high: 200)).to be_nil
      expect(described_class.for(price: 150, low: 100, high: nil)).to be_nil
      expect(described_class.for(price: nil, low: 100, high: 200)).to be_nil
    end

    it "returns nil when the bounds cannot describe a range" do
      expect(described_class.for(price: 150, low: 200, high: 100)).to be_nil
      expect(described_class.for(price: 150, low: 150, high: 150)).to be_nil
    end
  end

  describe "#position_of" do
    it "places any other price on the track the reading already describes" do
      expect(reading(150).position_of(125)).to eq(0.25)
      expect(reading(150).position_of(200)).to eq(1)
    end

    it "clamps a cost older than the year rather than running off the bar" do
      expect(reading(150).position_of(40)).to eq(0)
      expect(reading(150).position_of(260)).to eq(1)
    end

    it "returns nil when there is no price to place, so nothing is drawn" do
      expect(reading(150).position_of(nil)).to be_nil
    end
  end
end
