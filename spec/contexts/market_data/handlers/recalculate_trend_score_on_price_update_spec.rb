require "rails_helper"

RSpec.describe MarketData::Handlers::RecalculateTrendScoreOnPriceUpdate do
  describe ".async?" do
    it "is async" do
      expect(described_class.async?).to be true
    end
  end

  describe ".call" do
    let(:asset) { create(:asset, :stock) }

    context "with sufficient price history" do
      before do
        20.times do |i|
          create(:asset_price_history, asset: asset, date: (20 - i).days.ago, close: 100.0 + i)
        end
      end

      it "creates a TrendScore record" do
        event = MarketData::Events::AssetPriceUpdated.new(asset_id: asset.id, symbol: asset.symbol, new_price: "120.0", old_price: "119.0")

        expect { described_class.call(event) }.to change { asset.trend_scores.count }.by(1)

        score = asset.trend_scores.last
        expect(score.score).to be_between(0, 100)
        expect(score.label).to be_present
        expect(score.direction).to be_present
        expect(score.calculated_at).to be_present
      end
    end

    context "with insufficient price history" do
      before do
        5.times do |i|
          create(:asset_price_history, asset: asset, date: (5 - i).days.ago, close: 100.0 + i)
        end
      end

      it "does not create a TrendScore record" do
        event = MarketData::Events::AssetPriceUpdated.new(asset_id: asset.id, symbol: asset.symbol, new_price: "105.0", old_price: "104.0")

        expect { described_class.call(event) }.not_to change(TrendScore, :count)
      end
    end

    context "when asset is not found" do
      it "does nothing" do
        event = MarketData::Events::AssetPriceUpdated.new(asset_id: -1, symbol: "FAKE", new_price: "100.0", old_price: "99.0")

        expect { described_class.call(event) }.not_to change(TrendScore, :count)
      end
    end
  end
end
