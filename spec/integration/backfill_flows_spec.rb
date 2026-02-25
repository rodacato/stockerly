require "rails_helper"

RSpec.describe "Backfill Flows (E2E)", type: :model do
  include ActiveJob::TestHelper

  describe "first boot scenario" do
    let!(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active) }

    before do
      stub_polygon_historical("AAPL")
    end

    it "detects asset with no history and backfills via BackfillMissingHistoriesJob" do
      expect(asset.asset_price_histories.count).to eq(0)

      perform_enqueued_jobs do
        BackfillMissingHistoriesJob.perform_now
      end

      expect(asset.asset_price_histories.reload.count).to be > 0
      expect(SystemLog.where(task_name: "Backfill Missing Histories", severity: :success).count).to eq(1)
    end

    it "skips assets that already have sufficient history" do
      10.times { |i| create(:asset_price_history, asset: asset, date: i.days.ago.to_date) }

      expect { BackfillMissingHistoriesJob.perform_now }
        .not_to have_enqueued_job(BackfillPriceHistoryJob)
    end
  end
end
