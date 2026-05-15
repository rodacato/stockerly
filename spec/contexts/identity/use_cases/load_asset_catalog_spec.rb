require "rails_helper"

RSpec.describe Identity::UseCases::LoadAssetCatalog do
  describe ".call" do
    before do
      create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock)
      create(:asset, symbol: "BTC", name: "Bitcoin", asset_type: :crypto)
      create(:asset, symbol: "SPX", name: "S&P 500", asset_type: :index)
    end

    it "returns stocks, crypto, and ETFs by default — indices excluded" do
      symbols = described_class.call.map(&:symbol)
      expect(symbols).to include("AAPL", "BTC")
      expect(symbols).not_to include("SPX")
    end

    it "accepts custom types" do
      symbols = described_class.call(types: [ :stock ]).map(&:symbol)
      expect(symbols).to include("AAPL")
      expect(symbols).not_to include("BTC")
    end

    it "respects the limit parameter" do
      expect(described_class.call(limit: 1).count).to eq(1)
    end
  end
end
