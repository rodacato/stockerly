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

    describe "failure_reasons batching (regression: gemini review on #137)" do
      it "returns a hash keyed by symbol with last failure tuples" do
        broken = create(:asset, :sync_issue, symbol: "BRK1", name: "Broken One")
        create(:system_log, :error, task_name: "All Gateways Failed: BRK1", module_name: "sync",
                                     error_message: "HTTP 429", created_at: 5.minutes.ago)
        create(:system_log, :error, task_name: "All Gateways Failed: BRK1", module_name: "sync",
                                     error_message: "HTTP 500", created_at: 2.minutes.ago)

        result = described_class.call(params: {})
        fr = result.value![:failure_reasons]
        expect(fr).to have_key(broken.symbol)
        expect(fr[broken.symbol].first).to eq("HTTP 500") # latest wins
      end

      it "runs at most a bounded number of SQL queries regardless of broken-asset count" do
        12.times do |i|
          a = create(:asset, :sync_issue, symbol: "BRK#{i}", name: "Broken #{i}")
          create(:system_log, :error, task_name: "All Gateways Failed: #{a.symbol}",
                                       module_name: "sync", error_message: "boom #{i}",
                                       created_at: i.minutes.ago)
        end

        # Cap protects against the N+1 regression — total query count must
        # not scale with the number of broken assets.
        expect { described_class.call(params: {}) }.to make_queries(at_most: 10)
      end
    end
  end
end
