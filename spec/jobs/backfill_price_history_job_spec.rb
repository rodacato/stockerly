require "rails_helper"

RSpec.describe BackfillPriceHistoryJob, type: :job do
  before do
    create(:integration, provider_name: "Alpaca", api_key_encrypted: "PKID:secret")
    create(:integration, provider_name: "CoinGecko", api_key_encrypted: "test_key")
  end

  describe "#perform" do
    context "with a stock asset" do
      let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock) }

      before do
        bars = 7.times.map { |i| alpaca_bar(date: (7 - i).days.ago.to_date.to_s, close: 180.0 + i) }
        stub_alpaca_bars({ "AAPL" => bars })
      end

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
        stub_alpaca_bars({})
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
