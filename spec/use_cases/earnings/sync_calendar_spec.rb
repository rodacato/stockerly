require "rails_helper"

RSpec.describe Earnings::SyncCalendar do
  describe ".call" do
    let!(:apple) { create(:asset, symbol: "AAPL", asset_type: :stock) }

    it "syncs earnings events from gateway" do
      stub_polygon_earnings("AAPL", count: 2)

      result = described_class.call
      expect(result).to be_success
      expect(result.value!).to eq(2)
      expect(EarningsEvent.where(asset: apple).count).to eq(2)
    end

    it "upserts without duplicating on same report_date" do
      stub_polygon_earnings("AAPL", count: 2)

      described_class.call
      described_class.call

      expect(EarningsEvent.where(asset: apple).count).to eq(2)
    end

    it "skips assets where gateway fails" do
      stub_polygon_earnings_rate_limited("AAPL")

      result = described_class.call
      expect(result).to be_success
      expect(result.value!).to eq(0)
    end

    it "publishes EarningsSynced event" do
      stub_polygon_earnings("AAPL", count: 1)
      allow(EventBus).to receive(:publish)

      described_class.call

      expect(EventBus).to have_received(:publish).with(an_instance_of(EarningsSynced))
    end

    it "returns 0 when no stock assets exist" do
      apple.update!(asset_type: :crypto)

      result = described_class.call
      expect(result).to be_success
      expect(result.value!).to eq(0)
    end
  end
end
