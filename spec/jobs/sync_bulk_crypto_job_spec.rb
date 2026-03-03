require "rails_helper"

RSpec.describe SyncBulkCryptoJob, type: :job do
  describe "#perform" do
    let!(:btc) { create(:asset, :crypto, symbol: "BTC", current_price: 60_000.00, price_updated_at: 10.minutes.ago) }
    let!(:eth) { create(:asset, :crypto, symbol: "ETH", current_price: 3_000.00, price_updated_at: 10.minutes.ago) }

    context "when CoinGecko returns valid data" do
      before { stub_coingecko_prices }

      it "updates all crypto asset prices in a single API call" do
        described_class.perform_now([ btc.id, eth.id ])

        btc.reload
        eth.reload
        expect(btc.current_price.to_f).to eq(64_231.0)
        expect(eth.current_price.to_f).to eq(3_450.0)
      end

      it "updates price_updated_at for each asset" do
        described_class.perform_now([ btc.id, eth.id ])

        btc.reload
        expect(btc.price_updated_at).to be_within(2.seconds).of(Time.current)
      end

      it "publishes AssetPriceUpdated events for changed prices" do
        expect(EventBus).to receive(:publish).with(an_instance_of(MarketData::Events::AssetPriceUpdated)).twice

        described_class.perform_now([ btc.id, eth.id ])
      end

      it "creates a success SystemLog entry" do
        expect {
          described_class.perform_now([ btc.id, eth.id ])
        }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.severity).to eq("success")
        expect(log.task_name).to include("Bulk Crypto Sync")
        expect(log.module_name).to eq("sync")
      end
    end

    context "when CoinGecko is rate limited" do
      before { stub_coingecko_rate_limited }

      it "creates a warning SystemLog entry" do
        described_class.perform_now([ btc.id, eth.id ])

        log = SystemLog.last
        expect(log.severity).to eq("warning")
      end

      it "does not update asset prices" do
        described_class.perform_now([ btc.id, eth.id ])

        btc.reload
        expect(btc.current_price.to_f).to eq(60_000.0)
      end
    end

    context "when no active assets found" do
      let!(:disabled) { create(:asset, :crypto, :disabled, symbol: "DOGE") }

      it "does nothing" do
        expect {
          described_class.perform_now([ disabled.id ])
        }.not_to change(SystemLog, :count)
      end
    end

    context "when asset list is empty" do
      it "does nothing" do
        expect {
          described_class.perform_now([])
        }.not_to change(SystemLog, :count)
      end
    end
  end
end
