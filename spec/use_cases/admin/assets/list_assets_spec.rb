require "rails_helper"

RSpec.describe Admin::Assets::ListAssets do
  describe ".call" do
    before do
      create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock, sync_status: :active)
      create(:asset, symbol: "BTC", name: "Bitcoin", asset_type: :crypto, sync_status: :active)
      create(:asset, symbol: "ETH", name: "Ethereum", asset_type: :crypto, sync_status: :disabled)
    end

    it "returns all assets with pagination" do
      result = described_class.call(params: {})

      expect(result).to be_success
      data = result.value!
      expect(data[:assets].count).to eq(3)
      expect(data[:pagy]).to be_a(Pagy)
      expect(data[:total_count]).to eq(3)
      expect(data[:syncing_count]).to eq(2)
    end

    it "filters by type" do
      result = described_class.call(params: { type: "crypto" })
      expect(result.value![:assets].count).to eq(2)
    end

    it "searches by name or symbol" do
      result = described_class.call(params: { search: "apple" })
      expect(result.value![:assets].count).to eq(1)
      expect(result.value![:assets].first.symbol).to eq("AAPL")
    end
  end
end
