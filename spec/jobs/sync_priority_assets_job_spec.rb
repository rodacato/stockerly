require "rails_helper"

RSpec.describe SyncPriorityAssetsJob, type: :job do
  include ActiveSupport::Testing::TimeHelpers

  describe "#perform" do
    let(:user) { create(:user) }

    context "with high-priority crypto assets" do
      let!(:btc) { create(:asset, :crypto, symbol: "BTC") }
      let!(:eth) { create(:asset, :crypto, symbol: "ETH") }

      before do
        create(:watchlist_item, user: user, asset: btc)
      end

      it "enqueues SyncBulkCryptoJob with high-priority asset IDs" do
        expect {
          described_class.perform_now("crypto", "high")
        }.to have_enqueued_job(SyncBulkCryptoJob).with([btc.id])
      end

      it "does not include low-priority crypto assets" do
        expect {
          described_class.perform_now("crypto", "high")
        }.to have_enqueued_job(SyncBulkCryptoJob).with([btc.id])
      end
    end

    context "with low-priority crypto assets" do
      let!(:btc) { create(:asset, :crypto, symbol: "BTC") }
      let!(:eth) { create(:asset, :crypto, symbol: "ETH") }

      before do
        create(:watchlist_item, user: user, asset: btc)
      end

      it "enqueues SyncBulkCryptoJob with only low-priority asset IDs" do
        expect {
          described_class.perform_now("crypto", "low")
        }.to have_enqueued_job(SyncBulkCryptoJob).with([eth.id])
      end
    end

    context "with US stock assets during market hours" do
      let!(:aapl) { create(:asset, symbol: "AAPL", asset_type: :stock, exchange: "NASDAQ") }

      before do
        create(:watchlist_item, user: user, asset: aapl)
      end

      it "enqueues SyncSingleAssetJob when US market is open" do
        travel_to Time.zone.parse("2025-01-15 12:00:00 EST") do
          expect {
            described_class.perform_now("stock", "high")
          }.to have_enqueued_job(SyncSingleAssetJob).with(aapl.id)
        end
      end

      it "does not enqueue when US market is closed" do
        travel_to Time.zone.parse("2025-01-15 22:00:00 EST") do
          expect {
            described_class.perform_now("stock", "high")
          }.not_to have_enqueued_job(SyncSingleAssetJob)
        end
      end
    end

    context "with BMV assets during market hours" do
      let!(:mx_stock) { create(:asset, :mexican, symbol: "GENIUSSACV.MX", asset_type: :stock) }

      before do
        create(:watchlist_item, user: user, asset: mx_stock)
      end

      it "enqueues SyncBulkBmvJob when BMV is open" do
        travel_to Time.zone.parse("2025-01-15 12:00:00 CST") do
          expect {
            described_class.perform_now("stock", "high")
          }.to have_enqueued_job(SyncBulkBmvJob).with([mx_stock.id])
        end
      end

      it "does not enqueue when BMV is closed" do
        travel_to Time.zone.parse("2025-01-15 22:00:00 CST") do
          expect {
            described_class.perform_now("stock", "high")
          }.not_to have_enqueued_job(SyncBulkBmvJob)
        end
      end
    end

    context "with no matching assets" do
      it "does nothing" do
        expect {
          described_class.perform_now("stock", "high")
        }.not_to have_enqueued_job(SyncSingleAssetJob)
      end
    end
  end
end
