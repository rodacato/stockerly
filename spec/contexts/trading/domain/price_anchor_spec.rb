require "rails_helper"

RSpec.describe Trading::Domain::PriceAnchor do
  describe ".against_cost" do
    it "reads the price as a gain over what you paid" do
      result = described_class.against_cost(price: 184.20, cost: 120)

      expect(result.kind).to eq(:cost)
      expect(result.reference).to eq(120)
      expect(result.percent).to eq(53.5)
    end

    it "signs a price below cost negative" do
      expect(described_class.against_cost(price: 90, cost: 120).percent).to eq(-25.0)
    end

    it "returns nil rather than dividing by a cost of zero" do
      expect(described_class.against_cost(price: 100, cost: 0)).to be_nil
      expect(described_class.against_cost(price: 100, cost: nil)).to be_nil
      expect(described_class.against_cost(price: nil, cost: 100)).to be_nil
    end
  end

  describe ".against_threshold" do
    it "reads how far the price still has to fall to reach a buy-below target" do
      result = described_class.against_threshold(price: 248.50, threshold: 220)

      expect(result.kind).to eq(:threshold)
      expect(result.reference).to eq(220)
      expect(result.percent).to eq(-11.5)
    end

    it "reads a target above the price as a rise still owed" do
      expect(described_class.against_threshold(price: 100, threshold: 115).percent).to eq(15.0)
    end

    it "returns nil rather than dividing by a price of zero" do
      expect(described_class.against_threshold(price: 0, threshold: 220)).to be_nil
      expect(described_class.against_threshold(price: 100, threshold: nil)).to be_nil
    end
  end
end
