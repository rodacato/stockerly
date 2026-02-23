require "rails_helper"

RSpec.describe LogAllGatewaysFailure do
  let(:asset) { create(:asset, symbol: "AAPL", sync_status: :active) }

  describe ".call" do
    it "creates an error SystemLog entry" do
      event = AllGatewaysFailed.new(
        asset_id: asset.id,
        symbol: "AAPL",
        attempted_gateways: %w[PolygonGateway YahooFinanceGateway]
      )

      expect {
        described_class.call(event)
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.severity).to eq("error")
      expect(log.task_name).to eq("All Gateways Failed: AAPL")
      expect(log.error_message).to include("PolygonGateway")
      expect(log.error_message).to include("YahooFinanceGateway")
    end

    it "marks asset as sync_issue after threshold consecutive failures" do
      3.times do
        described_class.call(
          asset_id: asset.id,
          symbol: "AAPL",
          attempted_gateways: %w[PolygonGateway]
        )
      end

      asset.reload
      expect(asset.sync_status).to eq("sync_issue")
    end

    it "does not mark sync_issue below threshold" do
      2.times do
        described_class.call(
          asset_id: asset.id,
          symbol: "AAPL",
          attempted_gateways: %w[PolygonGateway]
        )
      end

      asset.reload
      expect(asset.sync_status).to eq("active")
    end

    it "handles hash events from async dispatch" do
      event = {
        asset_id: asset.id,
        symbol: "AAPL",
        attempted_gateways: %w[PolygonGateway]
      }

      expect {
        described_class.call(event)
      }.to change(SystemLog, :count).by(1)
    end
  end
end
