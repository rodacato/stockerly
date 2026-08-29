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

      it "persists the factors the calculator returned" do
        described_class.perform_now

        expect(active_asset.trend_scores.last.factors).to include("rsi", "momentum")
      end
    end

    context "with enough price history for the five-factor blend" do
      before do
        40.times do |i|
          create(:asset_price_history,
                 asset: active_asset,
                 date: (40 - i).days.ago,
                 close: 100.0 + i,
                 volume: 1_000_000 + (i * 10_000))
        end
      end

      it "persists every factor, including the volume-dependent one" do
        described_class.perform_now

        factors = active_asset.trend_scores.last.factors

        expect(factors.keys).to match_array(%w[rsi momentum macd volume_trend ema_crossover])
        expect(factors["volume_trend"]).not_to be_nil
        expect(factors["macd"]).not_to be_nil
        expect(factors["ema_crossover"]).not_to be_nil
      end

      it "matches what the handler would have persisted for the same asset" do
        described_class.perform_now
        job_score = active_asset.trend_scores.last

        MarketData::Handlers::RecalculateTrendScoreOnPriceUpdate.call(asset_id: active_asset.id)
        handler_score = active_asset.trend_scores.reload.last

        expect(job_score.score).to eq(handler_score.score)
        expect(job_score.factors).to eq(handler_score.factors)
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
