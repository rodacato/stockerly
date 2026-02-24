require "rails_helper"

RSpec.describe CalculateTrendScoresJob, type: :job do
  describe "#perform" do
    let!(:active_asset) { create(:asset, :stock, sync_status: :active) }
    let!(:disabled_asset) { create(:asset, :stock, sync_status: :disabled, symbol: "DIS") }

    context "with sufficient price history" do
      before do
        20.times do |i|
          create(:asset_price_history, asset: active_asset, date: (20 - i).days.ago, close: 100.0 + i)
        end
      end

      it "creates TrendScore for active assets" do
        expect { described_class.perform_now }.to change { active_asset.trend_scores.count }.by(1)
      end

      it "does not create TrendScore for disabled assets" do
        expect { described_class.perform_now }.not_to change { disabled_asset.trend_scores.count }
      end

      it "logs sync success with count" do
        expect_any_instance_of(described_class).to receive(:log_sync_success).with("TrendScores: 1 assets scored")
        described_class.perform_now
      end
    end

    context "with insufficient price history" do
      before do
        5.times do |i|
          create(:asset_price_history, asset: active_asset, date: (5 - i).days.ago, close: 100.0 + i)
        end
      end

      it "skips assets without enough data" do
        expect { described_class.perform_now }.not_to change(TrendScore, :count)
      end
    end
  end
end
