require "rails_helper"

RSpec.describe Administration::UseCases::Assets::ToggleStatus do
  describe ".call" do
    it "disables an active asset" do
      asset = create(:asset, sync_status: :active)
      result = described_class.call(asset_id: asset.id)
      expect(result.sync_status).to eq("disabled")
    end

    it "activates a disabled asset" do
      asset = create(:asset, sync_status: :disabled)
      result = described_class.call(asset_id: asset.id)
      expect(result.sync_status).to eq("active")
    end

    it "raises ActiveRecord::RecordNotFound for an unknown asset id" do
      expect {
        described_class.call(asset_id: 999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
