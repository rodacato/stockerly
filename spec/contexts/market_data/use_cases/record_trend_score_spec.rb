require "rails_helper"

RSpec.describe MarketData::UseCases::RecordTrendScore do
  let(:asset) { create(:asset, :stock) }

  context "with sufficient price history" do
    before do
      20.times { |i| create(:asset_price_history, asset: asset, date: (20 - i).days.ago, close: 100.0 + i) }
    end

    it "records one score carrying the calculator's reading" do
      expect { described_class.call(asset: asset) }.to change { asset.trend_scores.count }.by(1)

      score = asset.trend_scores.last
      expect(score.score).to be_between(0, 100)
      expect(score.label).to be_present
      expect(score.direction).to be_present
      expect(score.calculated_at).to be_present
      expect(score.factors).to include("rsi", "momentum")
    end

    it "returns the row it wrote" do
      expect(described_class.call(asset: asset)).to eq(asset.trend_scores.last)
    end
  end

  context "with insufficient price history" do
    before do
      5.times { |i| create(:asset_price_history, asset: asset, date: (5 - i).days.ago, close: 100.0 + i) }
    end

    it "writes nothing and returns nil" do
      expect { expect(described_class.call(asset: asset)).to be_nil }.not_to change(TrendScore, :count)
    end
  end
end
