require "rails_helper"

RSpec.describe SyncBulkStocksJob, type: :job do
  before do
    create(:integration, provider_name: "Alpaca", api_key_encrypted: "PKID:secret")
    GatewayChain.reset_breakers!
  end

  describe "#perform" do
    let!(:aapl) { create(:asset, symbol: "AAPL", asset_type: :stock, current_price: 180.00, price_updated_at: 10.minutes.ago) }
    let!(:msft) { create(:asset, symbol: "MSFT", asset_type: :stock, current_price: 400.00, price_updated_at: 10.minutes.ago) }

    context "when Alpaca returns confirmed daily closes" do
      before do
        today = Date.current.to_s
        stub_alpaca_bars({
          "AAPL" => [ alpaca_bar(date: today, open: 180.0, close: 189.43, volume: 58_000_000) ],
          "MSFT" => [ alpaca_bar(date: today, open: 400.0, close: 420.10, volume: 30_000_000) ],
          "UNKNOWN" => [ alpaca_bar(date: today, open: 50.0, close: 55.0, volume: 1000) ]
        })
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
        expect(EventBus).to receive(:publish).with(an_instance_of(MarketData::Events::AssetPriceUpdated)).twice

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

    context "when Alpaca is rate limited" do
      before { stub_alpaca_rate_limited }

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
