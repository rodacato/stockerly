require "rails_helper"

RSpec.describe Administration::UseCases::Assets::ListAssets do
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

    it "filters by sync status" do
      result = described_class.call(params: { status: "disabled" })
      expect(result.value![:assets].count).to eq(1)
      expect(result.value![:assets].first.symbol).to eq("ETH")
    end

    it "combines type and status filters" do
      result = described_class.call(params: { type: "crypto", status: "active" })
      expect(result.value![:assets].count).to eq(1)
      expect(result.value![:assets].first.symbol).to eq("BTC")
    end

    describe "market filter" do
      it "filters by a known market" do
        create(:asset, symbol: "AMXL", name: "América Móvil", exchange: "BMV", asset_type: :stock)
        result = described_class.call(params: { market: "BMV" })
        expect(result.value![:assets].map(&:symbol)).to eq([ "AMXL" ])
      end

      it "filters by Otros (long-tail and nil exchanges)" do
        create(:asset, symbol: "XPTO", name: "Otro", exchange: "OTHER_EX")
        result = described_class.call(params: { market: "Otros" })
        symbols = result.value![:assets].map(&:symbol)
        expect(symbols).to include("XPTO")
        expect(symbols).not_to include("AAPL")
      end
    end

    describe "sync_error health filter" do
      it "returns only assets whose last sync failed" do
        broken = create(:asset, :sync_error, symbol: "BRK1", name: "Broken One")
        create(:asset, symbol: "OKAY", name: "All Good", last_synced_at: Time.current)

        symbols = described_class.call(params: { status: "sync_error" }).value![:assets].map(&:symbol)
        expect(symbols).to include(broken.symbol)
        expect(symbols).not_to include("OKAY")
      end

      it "keeps a failed asset active — a failure never pauses it" do
        expect(create(:asset, :sync_error, symbol: "BRK2").sync_status).to eq("active")
      end
    end
  end
end
