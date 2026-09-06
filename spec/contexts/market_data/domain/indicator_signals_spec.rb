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
      expect(described_class.for(r).pluck(:indicator)).not_to include(:moving_average)
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
      expect(described_class.for(r).pluck(:indicator)).not_to include(:bollinger)
    end
  end

  # D110: the one row here with no state. Measured across the assets on file the
  # figure spans 0.27% to 7.2%, so a "volatile" threshold would be invented and
  # D36 forbids it -- the magnitude is the whole reading.
  describe "the ATR row" do
    def reading(atr:, close:)
      { atr: atr, close: close }
    end

    it "states the daily range as a share of the asset's own price" do
      row = described_class.for(reading(atr: 7.2478, close: 230.72)).find { |s| s[:indicator] == :atr }

      expect(row[:state]).to eq(:rango_diario)
      expect(row[:value].to_f).to be_within(0.01).of(3.14)
    end

    it "is absent when the reading carried no ATR" do
      expect(described_class.for(reading(atr: nil, close: 230.72)).pluck(:indicator)).not_to include(:atr)
    end

    # A percentage of nothing is not a reading.
    it "is absent when there is no close to divide by" do
      expect(described_class.for(reading(atr: 7.2478, close: nil)).pluck(:indicator)).not_to include(:atr)
      expect(described_class.for(reading(atr: 7.2478, close: 0)).pluck(:indicator)).not_to include(:atr)
    end
  end
end
