require "rails_helper"

RSpec.describe SyncBulkStocksJob, type: :job do
  before do
    SyncSingleAssetJob::CIRCUIT_BREAKERS.each_value(&:reset!)
  end

  describe "#perform" do
    let!(:aapl) { create(:asset, symbol: "AAPL", asset_type: :stock, current_price: 180.00, price_updated_at: 10.minutes.ago) }
    let!(:msft) { create(:asset, symbol: "MSFT", asset_type: :stock, current_price: 400.00, price_updated_at: 10.minutes.ago) }

    context "when Polygon returns grouped daily data" do
      before do
        stub_request(:get, %r{api\.polygon\.io/v2/aggs/grouped/locale/us/market/stocks/})
          .with(query: hash_including("apiKey"))
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: {
              results: [
                { "T" => "AAPL", "o" => 180.0, "c" => 189.43, "h" => 191.0, "l" => 179.0, "v" => 58_000_000 },
                { "T" => "MSFT", "o" => 400.0, "c" => 420.10, "h" => 425.0, "l" => 398.0, "v" => 30_000_000 },
                { "T" => "UNKNOWN", "o" => 50.0, "c" => 55.0, "h" => 56.0, "l" => 49.0, "v" => 1000 }
              ],
              resultsCount: 3
            }.to_json
          )
      end

      it "updates stock asset prices" do
        described_class.perform_now([ aapl.id, msft.id ])

        aapl.reload
        msft.reload
        expect(aapl.current_price.to_f).to eq(189.43)
        expect(msft.current_price.to_f).to eq(420.10)
      end

      it "updates price_updated_at" do
        described_class.perform_now([ aapl.id, msft.id ])

        aapl.reload
        expect(aapl.price_updated_at).to be_within(2.seconds).of(Time.current)
      end

      it "publishes AssetPriceUpdated events for changed prices" do
        expect(EventBus).to receive(:publish).with(an_instance_of(MarketData::AssetPriceUpdated)).twice

        described_class.perform_now([ aapl.id, msft.id ])
      end

      it "logs success with count" do
        expect {
          described_class.perform_now([ aapl.id, msft.id ])
        }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.severity).to eq("success")
        expect(log.task_name).to include("Bulk Stock Sync")
      end

      it "skips symbols not in the asset list" do
        described_class.perform_now([ aapl.id, msft.id ])

        # UNKNOWN symbol was in results but not in our assets
        expect(Asset.find_by(symbol: "UNKNOWN")).to be_nil
      end
    end

    context "when Polygon is rate limited" do
      before do
        stub_request(:get, %r{api\.polygon\.io/v2/aggs/grouped/locale/us/market/stocks/})
          .to_return(status: 429, body: "Rate limited")
      end

      it "logs a warning" do
        described_class.perform_now([ aapl.id ])

        log = SystemLog.last
        expect(log.severity).to eq("warning")
      end
    end

    context "with no active assets" do
      let!(:disabled) { create(:asset, :disabled, symbol: "DIS", asset_type: :stock) }

      it "does nothing" do
        expect {
          described_class.perform_now([ disabled.id ])
        }.not_to change(SystemLog, :count)
      end
    end
  end
end
