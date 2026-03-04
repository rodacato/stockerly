require "rails_helper"

RSpec.describe Administration::Domain::AssetCatalog do
  describe ".all" do
    it "returns a hash of categories" do
      catalog = described_class.all
      expect(catalog).to be_a(Hash)
      expect(catalog.keys).to include(:us_stocks, :crypto, :etfs, :mexican_stocks, :fixed_income)
    end
  end

  describe ".flat" do
    it "returns all assets as a flat array" do
      flat = described_class.flat
      expect(flat).to be_an(Array)
      expect(flat.size).to be >= 25
      expect(flat.first).to include(:symbol, :name, :asset_type)
    end
  end

  describe ".symbols" do
    it "returns all symbols" do
      symbols = described_class.symbols
      expect(symbols).to include("AAPL", "BTC", "SPY", "CETE28D")
    end
  end

  describe ".find_by_symbols" do
    it "returns matching entries" do
      results = described_class.find_by_symbols(%w[AAPL BTC])
      expect(results.size).to eq(2)
      expect(results.map { |r| r[:symbol] }).to contain_exactly("AAPL", "BTC")
    end

    it "ignores unknown symbols" do
      results = described_class.find_by_symbols(%w[AAPL UNKNOWN])
      expect(results.size).to eq(1)
    end
  end

  describe ".category_label" do
    it "returns human-readable label for known key" do
      expect(described_class.category_label(:us_stocks)).to eq("US Stocks")
      expect(described_class.category_label(:crypto)).to eq("Cryptocurrency")
    end
  end

  describe "DEFAULT_SELECTED" do
    it "contains popular symbols" do
      expect(described_class::DEFAULT_SELECTED).to include("AAPL", "BTC", "SPY")
    end
  end
end
