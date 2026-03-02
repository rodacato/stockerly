require "rails_helper"

RSpec.describe Identity::LoadAssetCatalog do
  describe ".call" do
    before do
      create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock)
      create(:asset, symbol: "BTC", name: "Bitcoin", asset_type: :crypto)
      create(:asset, symbol: "SPX", name: "S&P 500", asset_type: :index)
    end

    it "returns stocks and crypto by default, excluding indices" do
      result = described_class.call

      expect(result).to be_success
      symbols = result.value![:assets].map(&:symbol)
      expect(symbols).to include("AAPL", "BTC")
      expect(symbols).not_to include("SPX")
    end

    it "accepts custom types" do
      result = described_class.call(types: [ :stock ])
      symbols = result.value![:assets].map(&:symbol)
      expect(symbols).to include("AAPL")
      expect(symbols).not_to include("BTC")
    end

    it "limits results" do
      result = described_class.call(limit: 1)
      expect(result.value![:assets].count).to eq(1)
    end
  end
end
