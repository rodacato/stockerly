require "rails_helper"

RSpec.describe "Sync Recovery (E2E)", type: :model do
  include ActiveJob::TestHelper

  before do
    create(:integration, provider_name: "Polygon.io", pool_key_value: "test_key")
  end

  describe "recovery from sync_issue" do
    let!(:asset) do
      create(:asset,
        symbol: "AAPL",
        asset_type: :stock,
        sync_status: :sync_issue,
        sync_issue_since: 2.days.ago,
        current_price: 150.00,
        price_updated_at: 3.days.ago)
    end

    it "RetryFailedAssetsJob re-syncs stuck asset and clears sync_issue" do
      stub_polygon_price("AAPL", close: 189.43)

      RetryFailedAssetsJob.perform_now

      asset.reload
      expect(asset.sync_status).to eq("active")
      expect(asset.sync_issue_since).to be_nil
      expect(asset.current_price.to_f).to eq(189.43)
      expect(SystemLog.where(task_name: "Retry Recovered: AAPL").count).to eq(1)
    end

    it "auto-disables asset after 7 days of sync_issue" do
      asset.update!(sync_issue_since: 8.days.ago)

      RetryFailedAssetsJob.perform_now

      asset.reload
      expect(asset.sync_status).to eq("disabled")
    end
  end
end
