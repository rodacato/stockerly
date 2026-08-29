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

    context "with a stock's calendar rather than a crypto's" do
      let(:window) { MarketData::Domain::TrendScoreCalculator::WINDOW }

      # Weekdays only, minus four market holidays inside the most recent weeks.
      # That is what drops a 50-calendar-day window under MACD's 34 closes while
      # a 60-row window is unaffected.
      before do
        rows = 0
        weekdays = 0
        offset = 0
        while rows < window
          day = Date.current - offset
          offset += 1
          next if day.saturday? || day.sunday?

          weekdays += 1
          next if [ 5, 10, 15, 20 ].include?(weekdays)

          create(:asset_price_history, asset: asset, date: day, close: 100.0 + rows, volume: 1_000_000 + (rows * 1_000))
          rows += 1
        end
      end

      it "reaches macd because the window counts rows, not calendar days" do
        series = MarketData::Queries::PriceSeries.for(asset)

        expect(series.latest(window).size).to eq(window)
        # The window this replaced. Under 34, MACD cannot be computed at all.
        expect(series.recent(50).count).to be < 34

        event = MarketData::Events::AssetPriceUpdated.new(asset_id: asset.id, symbol: asset.symbol, new_price: "160.0", old_price: "159.0")
        described_class.call(event)

        expect(asset.trend_scores.last.factors.keys)
          .to match_array(%w[rsi momentum macd volume_trend ema_crossover])
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
