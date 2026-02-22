require "rails_helper"

RSpec.describe "Admin Sync Flow (E2E)", type: :model do
  include ActiveJob::TestHelper

  describe "trigger single asset sync" do
    let(:asset) { create(:asset, symbol: "AAPL", asset_type: :stock, sync_status: :active, current_price: 150.00) }

    before { stub_polygon_price("AAPL", close: 195.0) }

    it "enqueues job and updates price when performed" do
      # Use case enqueues the job
      result = Admin::Assets::TriggerSync.call(asset_id: asset.id)
      expect(result).to be_success

      # Perform the enqueued job
      perform_enqueued_jobs

      asset.reload
      expect(asset.current_price.to_f).to eq(195.0)
      expect(SystemLog.where(module_name: "sync").count).to be >= 1
    end
  end

  describe "trigger bulk asset sync" do
    let!(:stock) { create(:asset, asset_type: :stock, sync_status: :active) }
    let!(:crypto) { create(:asset, asset_type: :crypto, sync_status: :active) }

    it "enqueues SyncAllAssetsJob which fans out to SyncSingleAssetJob" do
      result = Admin::Assets::TriggerSync.call(asset_type: "stock")
      expect(result).to be_success

      expect(SyncAllAssetsJob).to have_been_enqueued.with("stock")
    end
  end

  describe "integration connectivity test" do
    let!(:integration) { create(:integration, provider_name: "Polygon.io", connection_status: :disconnected) }

    before { stub_polygon_price("AAPL") }

    it "enqueues job and updates connection status when performed" do
      result = Admin::Integrations::RefreshSync.call(integration_id: integration.id)
      expect(result).to be_success

      perform_enqueued_jobs

      integration.reload
      expect(integration.connection_status).to eq("connected")
      expect(integration.last_sync_at).to be_present
    end
  end
end
