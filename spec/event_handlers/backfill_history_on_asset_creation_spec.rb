require "rails_helper"

RSpec.describe BackfillHistoryOnAssetCreation do
  describe ".call" do
    it "enqueues BackfillPriceHistoryJob" do
      expect {
        described_class.call(asset_id: 42, symbol: "AAPL", admin_id: 1)
      }.to have_enqueued_job(BackfillPriceHistoryJob).with(42)
    end
  end

  describe ".async?" do
    it "returns true" do
      expect(described_class.async?).to be true
    end
  end
end
