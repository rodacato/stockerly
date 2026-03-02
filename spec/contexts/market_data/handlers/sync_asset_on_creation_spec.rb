require "rails_helper"

RSpec.describe MarketData::SyncAssetOnCreation do
  describe ".async?" do
    it "returns true" do
      expect(described_class.async?).to be true
    end
  end

  describe ".call" do
    let(:asset) { create(:asset, symbol: "MSFT") }

    it "enqueues SyncSingleAssetJob for the asset" do
      event = MarketData::AssetCreated.new(asset_id: asset.id, symbol: "MSFT", admin_id: 1)

      expect {
        described_class.call(event)
      }.to have_enqueued_job(SyncSingleAssetJob).with(asset.id)
    end

    it "handles hash events from async dispatch" do
      event = { asset_id: asset.id, symbol: "MSFT", admin_id: 1 }

      expect {
        described_class.call(event)
      }.to have_enqueued_job(SyncSingleAssetJob).with(asset.id)
    end
  end
end
