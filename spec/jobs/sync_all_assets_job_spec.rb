require "rails_helper"

RSpec.describe SyncAllAssetsJob, type: :job do
  describe "#perform" do
    let!(:stock) { create(:asset, asset_type: :stock, sync_status: :active) }
    let!(:crypto) { create(:asset, asset_type: :crypto, sync_status: :active) }
    let!(:disabled) { create(:asset, asset_type: :stock, sync_status: :disabled) }

    it "enqueues SyncSingleAssetJob for each active asset" do
      expect {
        described_class.perform_now
      }.to have_enqueued_job(SyncSingleAssetJob).exactly(2).times
    end

    it "filters by asset_type when provided" do
      expect {
        described_class.perform_now("stock")
      }.to have_enqueued_job(SyncSingleAssetJob).exactly(1).times
    end

    it "does not enqueue for disabled assets" do
      expect {
        described_class.perform_now
      }.not_to have_enqueued_job(SyncSingleAssetJob).with(disabled.id)
    end
  end
end
