require "rails_helper"

RSpec.describe Admin::Assets::TriggerSync do
  describe "#call" do
    context "with specific asset_id" do
      let(:asset) { create(:asset) }

      it "enqueues SyncSingleAssetJob" do
        expect {
          described_class.call(asset_id: asset.id)
        }.to have_enqueued_job(SyncSingleAssetJob).with(asset.id)
      end

      it "returns success" do
        result = described_class.call(asset_id: asset.id)

        expect(result).to be_success
        expect(result.value!).to eq(:single_sync_enqueued)
      end

      it "returns failure when asset not found" do
        result = described_class.call(asset_id: -1)

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:not_found)
      end
    end

    context "with asset_type (bulk sync)" do
      it "enqueues SyncAllAssetsJob" do
        expect {
          described_class.call(asset_type: "stock")
        }.to have_enqueued_job(SyncAllAssetsJob).with("stock")
      end

      it "returns success" do
        result = described_class.call(asset_type: "stock")

        expect(result).to be_success
        expect(result.value!).to eq(:bulk_sync_enqueued)
      end
    end
  end
end
