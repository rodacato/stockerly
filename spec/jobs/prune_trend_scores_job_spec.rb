require "rails_helper"

RSpec.describe PruneTrendScoresJob, type: :job do
  let(:asset) { create(:asset, :stock, symbol: "NVDA") }
  let(:cutoff) { described_class::RETENTION_DAYS.days.ago }

  def score_at(time, asset: self.asset, score: 50)
    create(:trend_score, asset: asset, score: score, calculated_at: time)
  end

  it "deletes readings past the retention window" do
    old = score_at(cutoff - 5.days)
    score_at(1.day.ago)

    expect { described_class.perform_now }.to change { TrendScore.count }.by(-1)
    expect(TrendScore.exists?(old.id)).to be false
  end

  it "keeps readings inside the window" do
    score_at(cutoff + 1.day)
    score_at(1.day.ago)

    expect { described_class.perform_now }.not_to(change { TrendScore.count })
  end

  # AlertEvaluator reads `latest_trend_score&.score || 0`, so pruning an asset
  # that stopped syncing down to nothing would silently score its alerts at 0.
  it "keeps the newest reading even when every one of them is past the window" do
    score_at(cutoff - 30.days, score: 10)
    newest = score_at(cutoff - 5.days, score: 80)

    described_class.perform_now

    expect(asset.reload.latest_trend_score&.id).to eq(newest.id)
    expect(TrendScore.where(asset: asset).count).to eq(1)
  end

  it "keeps the newest per asset rather than the newest overall" do
    stale = create(:asset, :stock, symbol: "STALE")
    stale_newest = score_at(cutoff - 10.days, asset: stale, score: 30)
    score_at(1.day.ago, score: 70)

    described_class.perform_now

    expect(TrendScore.exists?(stale_newest.id)).to be true
  end

  it "records what it deleted" do
    score_at(cutoff - 5.days)
    score_at(1.day.ago)

    expect { described_class.perform_now }.to change { SystemLog.count }.by(1)
    expect(SystemLog.last.error_message).to include("Deleted 1 rows")
  end
end
