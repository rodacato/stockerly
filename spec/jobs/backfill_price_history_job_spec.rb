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

      # Both links, or the chain falls through to the bridge for real: a
      # subprocess bypasses WebMock, which is how this spec was reaching Yahoo
      # from CI until the guard caught it.
      before do
        stub_alpaca_bars({})
        stub_yfinance_not_found("AAPL")
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
  # DataBursatil returns date and close only, so a BMV backfill must not blank
  # the OHLC another source already recorded for the same day.
  describe "a close-only bar over an existing full row" do
    let(:asset) { create(:asset, :mexican, symbol: "WALMEX.MX", asset_type: :stock) }
    let(:day) { 3.days.ago.to_date }

    let!(:existing) do
      AssetPriceHistory.create!(
        asset_id: asset.id, date: day, interval: "1d",
        open: 70.0, high: 72.0, low: 69.0, close: 71.0, volume: 1_000_000,
        source: "Yahoo Finance", status: "confirmed"
      )
    end

    it "updates the close and leaves the columns it has no value for" do
      job = described_class.new
      job.send(:upsert_bar, asset, { date: day, close: 71.5 }, "DataBursatil")

      existing.reload
      expect(existing.close.to_f).to eq(71.5)
      expect(existing.open.to_f).to eq(70.0)
      expect(existing.high.to_f).to eq(72.0)
      expect(existing.low.to_f).to eq(69.0)
      expect(existing.volume).to eq(1_000_000)
    end
  end
end
