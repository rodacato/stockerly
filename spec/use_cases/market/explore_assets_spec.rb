require "rails_helper"

RSpec.describe Market::ExploreAssets do
  let!(:apple) { create(:asset, name: "Apple Inc.", symbol: "AAPL", asset_type: :stock, sector: "Technology") }
  let!(:tesla) { create(:asset, name: "Tesla Inc.", symbol: "TSLA", asset_type: :stock, sector: "Automotive") }
  let!(:bitcoin) { create(:asset, name: "Bitcoin", symbol: "BTC", asset_type: :crypto) }
  let!(:index_spx) { create(:market_index, name: "S&P 500", symbol: "SPX") }

  describe "#call" do
    it "returns all assets with pagination" do
      result = described_class.call(params: {})
      expect(result).to be_success
      data = result.value!
      expect(data[:assets]).to include(apple, tesla, bitcoin)
      expect(data[:pagy]).to be_a(Pagy)
    end

    it "filters by asset type" do
      result = described_class.call(params: { type: "stock" })
      data = result.value!
      expect(data[:assets]).to include(apple, tesla)
      expect(data[:assets]).not_to include(bitcoin)
    end

    it "filters by sector" do
      result = described_class.call(params: { sector: "Technology" })
      data = result.value!
      expect(data[:assets]).to include(apple)
      expect(data[:assets]).not_to include(tesla)
    end

    it "searches by name or symbol" do
      result = described_class.call(params: { search: "apple" })
      data = result.value!
      expect(data[:assets]).to include(apple)
      expect(data[:assets]).not_to include(tesla, bitcoin)
    end

    it "returns major market indices" do
      result = described_class.call(params: {})
      data = result.value!
      expect(data[:indices]).to include(index_spx)
    end

    it "paginates results" do
      result = described_class.call(params: { page: 1 })
      data = result.value!
      expect(data[:pagy].page).to eq(1)
    end

    it "orders assets by symbol ascending" do
      result = described_class.call(params: {})
      symbols = result.value![:assets].map(&:symbol)
      expect(symbols).to eq(symbols.sort)
    end
  end
end
