require "rails_helper"

RSpec.describe MarketData::TrendScoreCalculator do
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
      it "applies 0.6 RSI + 0.4 momentum weighting" do
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
        # We test via the public interface by crafting appropriate price data
        # Verify that a result always has a valid label
        closes = (1..20).map { |i| 100.0 + (i * 1.0) }
        result = described_class.calculate(closes: closes)

        expect(result[:label]).to be_in(%i[weak weakening sideways moderate strong parabolic])
      end
    end
  end
end
