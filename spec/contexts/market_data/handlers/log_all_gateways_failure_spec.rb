require "rails_helper"

RSpec.describe MarketData::LogAllGatewaysFailure do
  let(:asset) { create(:asset, symbol: "AAPL", sync_status: :active) }

  describe ".call" do
    it "creates an error SystemLog entry" do
      event = MarketData::AllGatewaysFailed.new(
        asset_id: asset.id,
        symbol: "AAPL",
        attempted_gateways: %w[MarketData::PolygonGateway MarketData::YahooFinanceGateway]
      )

      expect {
        described_class.call(event)
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.severity).to eq("error")
      expect(log.task_name).to eq("All Gateways Failed: AAPL")
      expect(log.error_message).to include("MarketData::PolygonGateway")
      expect(log.error_message).to include("MarketData::YahooFinanceGateway")
    end

    it "marks asset as sync_issue after threshold consecutive failures" do
      3.times do
        described_class.call(
          asset_id: asset.id,
          symbol: "AAPL",
          attempted_gateways: %w[MarketData::PolygonGateway]
        )
      end

      asset.reload
      expect(asset.sync_status).to eq("sync_issue")
    end

    it "sets sync_issue_since when transitioning to sync_issue" do
      3.times do
        described_class.call(
          asset_id: asset.id,
          symbol: "AAPL",
          attempted_gateways: %w[MarketData::PolygonGateway]
        )
      end

      asset.reload
      expect(asset.sync_issue_since).to be_present
      expect(asset.sync_issue_since).to be_within(5.seconds).of(Time.current)
    end

    it "preserves sync_issue_since if already set" do
      original_time = 2.days.ago
      asset.update!(sync_status: :sync_issue, sync_issue_since: original_time)
      # Reset to active to trigger again
      asset.update!(sync_status: :active)

      3.times do
        described_class.call(
          asset_id: asset.id,
          symbol: "AAPL",
          attempted_gateways: %w[MarketData::PolygonGateway]
        )
      end

      asset.reload
      expect(asset.sync_issue_since).to be_within(1.second).of(original_time)
    end

    it "does not mark sync_issue below threshold" do
      2.times do
        described_class.call(
          asset_id: asset.id,
          symbol: "AAPL",
          attempted_gateways: %w[MarketData::PolygonGateway]
        )
      end

      asset.reload
      expect(asset.sync_status).to eq("active")
    end

    it "handles hash events from async dispatch" do
      event = {
        asset_id: asset.id,
        symbol: "AAPL",
        attempted_gateways: %w[MarketData::PolygonGateway]
      }

      expect {
        described_class.call(event)
      }.to change(SystemLog, :count).by(1)
    end
  end
end
