require "rails_helper"

RSpec.describe MarketData::Domain::TrendScoreCalculator do
  describe ".calculate" do
    it "returns nil when closes array is empty" do
      expect(described_class.calculate(closes: [])).to be_nil
    end

    it "returns nil when closes array is nil" do
      expect(described_class.calculate(closes: nil)).to be_nil
    end

    it "returns nil when closes array has fewer than 15 elements" do
      closes = Array.new(14) { |i| 100.0 + i }
      expect(described_class.calculate(closes: closes)).to be_nil
    end

    context "with uptrending data" do
      let(:closes) do
        # 20 days of steadily rising prices
        (1..20).map { |i| 100.0 + (i * 2.0) }
      end

      it "returns a high score with upward direction" do
        result = described_class.calculate(closes: closes)

        expect(result).to be_a(Hash)
        expect(result[:score]).to be_between(70, 100)
        expect(result[:direction]).to eq(:upward)
        expect(result[:label]).to be_in(%i[moderate strong parabolic])
      end
    end

    context "with downtrending data" do
      let(:closes) do
        # 20 days of steadily falling prices
        (1..20).map { |i| 200.0 - (i * 2.0) }
      end

      it "returns a low score with downward direction" do
        result = described_class.calculate(closes: closes)

        expect(result).to be_a(Hash)
        expect(result[:score]).to be_between(0, 40)
        expect(result[:direction]).to eq(:downward)
        expect(result[:label]).to be_in(%i[weak weakening])
      end
    end

    context "with flat prices" do
      let(:closes) do
        Array.new(20) { 150.0 }
      end

      it "returns a sideways score with upward direction (momentum = 0)" do
        result = described_class.calculate(closes: closes)

        expect(result).to be_a(Hash)
        expect(result[:score]).to be_between(40, 60)
        expect(result[:direction]).to eq(:upward)
        expect(result[:label]).to eq(:sideways)
      end
    end

    context "blending weights" do
      it "applies 0.6 RSI + 0.4 momentum weighting for < 35 closes" do
        # All gains → RSI close to 100, positive momentum
        closes = (1..20).map { |i| 100.0 + (i * 1.0) }
        result = described_class.calculate(closes: closes)

        # With pure uptrend: RSI ~100, momentum positive → high score
        expect(result[:score]).to be > 80
      end
    end

    context "score clamping" do
      it "clamps score to 0-100 range" do
        # Extreme uptrend
        closes = (1..20).map { |i| 50.0 + (i * 5.0) }
        result = described_class.calculate(closes: closes)

        expect(result[:score]).to be_between(0, 100)
      end
    end

    context "label classification" do
      it "maps scores to correct labels" do
        closes = (1..20).map { |i| 100.0 + (i * 1.0) }
        result = described_class.calculate(closes: closes)

        expect(result[:label]).to be_in(%i[weak weakening sideways moderate strong parabolic])
      end
    end

    context "5-factor mode (≥35 closes)" do
      let(:uptrend_closes) { (1..40).map { |i| 100.0 + (i * 1.5) } }
      let(:uptrend_volumes) { (1..40).map { |i| 1_000_000 + (i * 10_000) } }

      it "returns factors hash with all 5 keys" do
        result = described_class.calculate(closes: uptrend_closes, volumes: uptrend_volumes)

        expect(result[:factors]).to be_a(Hash)
        expect(result[:factors].keys).to contain_exactly(:rsi, :momentum, :macd, :volume_trend, :ema_crossover)
        result[:factors].each_value { |v| expect(v).to be_a(Float) }
      end

      it "falls back to 2-factor when closes are between 15 and 34" do
        closes = (1..25).map { |i| 100.0 + (i * 1.0) }
        result = described_class.calculate(closes: closes)

        expect(result[:factors].keys).to contain_exactly(:rsi, :momentum)
      end

      it "produces macd factor >= 50 for uptrend" do
        # Accelerating uptrend to produce positive MACD histogram
        accelerating = (1..40).map { |i| 100.0 + (i * 0.5) + (i > 25 ? (i - 25) * 3.0 : 0) }
        result = described_class.calculate(closes: accelerating)

        expect(result[:factors][:macd]).to be >= 50
      end

      it "produces volume_trend > 50 for spiking volume with upward momentum" do
        # Flat volume then sharp spike in last 5 days
        spiking_volumes = Array.new(35, 1_000_000) + Array.new(5, 3_000_000)
        result = described_class.calculate(closes: uptrend_closes, volumes: spiking_volumes)

        expect(result[:factors][:volume_trend]).to be > 50
      end

      it "produces ema_crossover > 50 for strong uptrend" do
        result = described_class.calculate(closes: uptrend_closes)

        expect(result[:factors][:ema_crossover]).to be > 50
      end
    end
  end
end
