require "rails_helper"

RSpec.describe Administration::UseCases::Assets::ToggleStatus do
  describe "#call" do
    it "disables an active asset" do
      asset = create(:asset, sync_status: :active)
      result = described_class.call(asset_id: asset.id)
      expect(result).to be_success
      expect(asset.reload.sync_status).to eq("disabled")
    end

    it "activates a disabled asset" do
      asset = create(:asset, sync_status: :disabled)
      result = described_class.call(asset_id: asset.id)
      expect(result).to be_success
      expect(asset.reload.sync_status).to eq("active")
    end

    it "returns failure when asset not found" do
      result = described_class.call(asset_id: 999)
      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end
  end
end
