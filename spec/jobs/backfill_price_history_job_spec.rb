require "rails_helper"

RSpec.describe BackfillPriceHistoryJob, type: :job do
  describe "#perform" do
    context "with a stock asset" do
      let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock) }

      before { stub_polygon_historical("AAPL", days: 7) }

      it "creates AssetPriceHistory records" do
        expect {
          described_class.perform_now(asset.id)
        }.to change(AssetPriceHistory, :count).by(7)
      end

      it "logs success" do
        expect {
          described_class.perform_now(asset.id)
        }.to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.task_name).to eq("Backfill: AAPL")
        expect(log.severity).to eq("success")
      end

      it "upserts without duplicates on re-run" do
        described_class.perform_now(asset.id)

        expect {
          described_class.perform_now(asset.id)
        }.not_to change(AssetPriceHistory, :count)
      end
    end

    context "with a crypto asset" do
      let(:asset) { create(:asset, symbol: "BTC", asset_type: :crypto) }

      before { stub_coingecko_historical(coin_id: "bitcoin", days: 7) }

      it "creates AssetPriceHistory records" do
        expect {
          described_class.perform_now(asset.id)
        }.to change(AssetPriceHistory, :count).by(7)
      end
    end

    context "when all gateways fail" do
      let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock) }

      before do
        stub_polygon_historical_empty("AAPL")
        stub_yahoo_finance_not_found("AAPL")
      end

      it "logs failure" do
        described_class.perform_now(asset.id)

        log = SystemLog.last
        expect(log.task_name).to eq("Backfill: AAPL")
        expect(log.severity).to eq("error")
      end
    end

    context "when asset does not exist" do
      it "does nothing" do
        expect {
          described_class.perform_now(999_999)
        }.not_to change(AssetPriceHistory, :count)
      end
    end
  end
end
