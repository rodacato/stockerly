require "rails_helper"

RSpec.describe MarketData::Domain::IndicatorSignals do
  def reading(**overrides)
    build(:technical_reading, readings: {
      "close" => 150.0, "rsi" => 55.0, "sma_50" => 145.0, "sma_200" => 130.0,
      "bb_upper" => 160.0, "bb_lower" => 136.0
    }.merge(overrides.transform_keys(&:to_s)))
  end

  it "returns no rows without a reading" do
    expect(described_class.for(nil)).to eq([])
  end

  describe "RSI" do
    it "names overbought at the threshold, not past it" do
      row = described_class.for(reading(rsi: 70.0)).find { |s| s[:indicator] == :rsi }
      expect(row[:state]).to eq(:overbought)
    end

    it "names oversold at the threshold" do
      row = described_class.for(reading(rsi: 30.0)).find { |s| s[:indicator] == :rsi }
      expect(row[:state]).to eq(:oversold)
    end

    it "is neutral between the thresholds" do
      row = described_class.for(reading(rsi: 55.0)).find { |s| s[:indicator] == :rsi }
      expect(row[:state]).to eq(:neutral)
    end
  end

  describe "moving averages" do
    it "reads the price against both averages" do
      row = described_class.for(reading(close: 150.0)).find { |s| s[:indicator] == :moving_average }
      expect(row[:state]).to eq(:above_both)
    end

    it "distinguishes being above one and below the other" do
      row = described_class.for(reading(close: 140.0)).find { |s| s[:indicator] == :moving_average }
      expect(row[:state]).to eq(:below_50_above_200)
    end

    # SMA200 needs 200 closes; a young asset has MA50 only and the row says
    # what it knows rather than inventing the half it does not have.
    it "falls back to MA50 alone when MA200 could not be computed" do
      r = build(:technical_reading, readings: { "close" => 150.0, "sma_50" => 145.0 })
      row = described_class.for(r).find { |s| s[:indicator] == :moving_average }
      expect(row[:state]).to eq(:above_50)
    end

    it "omits the row entirely when no average was computed" do
      r = build(:technical_reading, readings: { "close" => 150.0, "rsi" => 55.0 })
      expect(described_class.for(r).map { |s| s[:indicator] }).not_to include(:moving_average)
    end
  end

  describe "Bollinger" do
    it "reads a price above the upper band" do
      row = described_class.for(reading(close: 165.0)).find { |s| s[:indicator] == :bollinger }
      expect(row[:state]).to eq(:above_upper)
    end

    it "reads a price below the lower band" do
      row = described_class.for(reading(close: 130.0)).find { |s| s[:indicator] == :bollinger }
      expect(row[:state]).to eq(:below_lower)
    end

    it "reads a price inside the bands" do
      row = described_class.for(reading(close: 150.0)).find { |s| s[:indicator] == :bollinger }
      expect(row[:state]).to eq(:inside)
    end

    it "omits the row when the bands could not be computed" do
      r = build(:technical_reading, readings: { "close" => 150.0, "rsi" => 55.0 })
      expect(described_class.for(r).map { |s| s[:indicator] }).not_to include(:bollinger)
    end
  end
end
