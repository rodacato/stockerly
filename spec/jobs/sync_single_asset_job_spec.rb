require "rails_helper"

RSpec.describe SyncSingleAssetJob, type: :job do
  describe "#perform" do
    context "with a stock asset" do
      let!(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, current_price: 180.00, price_updated_at: 10.minutes.ago) }

      before { stub_polygon_price("AAPL", close: 189.43) }

      it "updates the asset price" do
        described_class.perform_now(asset.id)

        asset.reload
        expect(asset.current_price.to_f).to eq(189.43)
        expect(asset.price_updated_at).to be_present
      end

      it "creates a success SystemLog entry" do
        expect {
          described_class.perform_now(asset.id)
        }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.severity).to eq("success")
        expect(log.task_name).to include("AAPL")
        expect(log.module_name).to eq("sync")
      end
    end

    context "with a crypto asset" do
      let!(:asset) { create(:asset, symbol: "BTC", asset_type: :crypto, sync_status: :active, current_price: 60_000.00, price_updated_at: 10.minutes.ago) }

      before { stub_coingecko_prices }

      it "updates the asset price from CoinGecko" do
        described_class.perform_now(asset.id)

        asset.reload
        expect(asset.current_price.to_f).to eq(64_231.0)
      end
    end

    context "when gateway returns rate_limited" do
      let!(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, price_updated_at: 10.minutes.ago) }

      before { stub_polygon_rate_limited }

      it "creates a warning SystemLog entry" do
        described_class.perform_now(asset.id)

        log = SystemLog.last
        expect(log.severity).to eq("warning")
      end
    end

    context "when gateway returns server error" do
      let!(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, price_updated_at: 10.minutes.ago) }

      before { stub_polygon_server_error }

      it "creates an error SystemLog entry" do
        described_class.perform_now(asset.id)

        log = SystemLog.last
        expect(log.severity).to eq("error")
      end
    end

    context "when asset is disabled" do
      let!(:asset) { create(:asset, sync_status: :disabled) }

      it "does nothing" do
        expect {
          described_class.perform_now(asset.id)
        }.not_to change(SystemLog, :count)
      end
    end

    context "with a Mexican (BMV) stock" do
      let!(:asset) { create(:asset, :mexican, symbol: "GENIUSSACV.MX", asset_type: :stock, sync_status: :active, current_price: 20.00, price_updated_at: 10.minutes.ago) }

      before { stub_yahoo_finance_price("GENIUSSACV.MX", price: 25.50) }

      it "updates the asset price from Yahoo Finance" do
        described_class.perform_now(asset.id)

        asset.reload
        expect(asset.current_price.to_f).to eq(25.5)
      end

      it "creates a success SystemLog entry" do
        expect {
          described_class.perform_now(asset.id)
        }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.severity).to eq("success")
        expect(log.task_name).to include("GENIUSSACV.MX")
      end
    end

    context "with a Mexican ETF" do
      let!(:asset) { create(:asset, :mexican, :etf, symbol: "IVVPESO.MX", sync_status: :active, current_price: 40.00, price_updated_at: 10.minutes.ago) }

      before { stub_yahoo_finance_price("IVVPESO.MX", price: 48.30) }

      it "routes to YahooFinanceGateway, not PolygonGateway" do
        described_class.perform_now(asset.id)

        asset.reload
        expect(asset.current_price.to_f).to eq(48.3)
      end
    end

    context "when asset was recently synced" do
      let!(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, price_updated_at: 1.minute.ago) }

      it "skips sync for stocks updated within 4 minutes" do
        expect {
          described_class.perform_now(asset.id)
        }.not_to change(SystemLog, :count)
      end
    end

    context "when crypto asset was recently synced" do
      let!(:asset) { create(:asset, symbol: "BTC", asset_type: :crypto, sync_status: :active, price_updated_at: 1.minute.ago) }

      it "skips sync for crypto updated within 2 minutes" do
        expect {
          described_class.perform_now(asset.id)
        }.not_to change(SystemLog, :count)
      end
    end

    context "when asset has never been synced" do
      let!(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, price_updated_at: nil, current_price: 180.00) }

      before { stub_polygon_price("AAPL", close: 189.43) }

      it "proceeds with sync" do
        expect {
          described_class.perform_now(asset.id)
        }.to change(SystemLog, :count).by(1)
      end
    end

    context "when asset does not exist" do
      it "does nothing" do
        expect {
          described_class.perform_now(-1)
        }.not_to change(SystemLog, :count)
      end
    end
  end
end
