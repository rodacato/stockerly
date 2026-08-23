require "rails_helper"

RSpec.describe MarketData::Handlers::LogAllGatewaysFailure do
  let(:asset) { create(:asset, symbol: "AAPL", sync_status: :active) }

  describe ".call" do
    it "creates an error SystemLog entry" do
      event = MarketData::Events::AllGatewaysFailed.new(
        asset_id: asset.id,
        symbol: "AAPL",
        attempted_gateways: %w[MarketData::Gateways::PolygonGateway MarketData::Gateways::YahooFinanceGateway]
      )

      expect {
        described_class.call(event)
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.severity).to eq("error")
      expect(log.task_name).to eq("All Gateways Failed: AAPL")
      expect(log.error_message).to include("MarketData::Gateways::PolygonGateway")
      expect(log.error_message).to include("MarketData::Gateways::YahooFinanceGateway")
    end

    it "does not change the asset's status" do
      3.times do
        described_class.call(
          asset_id: asset.id,
          symbol: "AAPL",
          attempted_gateways: %w[MarketData::Gateways::PolygonGateway]
        )
      end

      expect(asset.reload.sync_status).to eq("active")
    end

    it "handles hash events from async dispatch" do
      event = {
        asset_id: asset.id,
        symbol: "AAPL",
        attempted_gateways: %w[MarketData::Gateways::PolygonGateway]
      }

      expect {
        described_class.call(event)
      }.to change(SystemLog, :count).by(1)
    end
  end
end
