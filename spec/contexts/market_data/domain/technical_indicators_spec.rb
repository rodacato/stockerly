require "rails_helper"

RSpec.describe MarketData::Domain::TechnicalIndicators do
  describe ".rsi" do
    it "returns nil when there are fewer than period+1 closes" do
      closes = (1..14).map(&:to_f) # exactly 14, need 15
      expect(described_class.rsi(closes)).to be_nil
    end

    it "returns 100.0 for a perfectly monotonic ascending series (no losses)" do
      closes = (1..20).map(&:to_f)
      expect(described_class.rsi(closes)).to eq(100.0)
    end

    it "returns 50.0 when there are no gains and no losses (flat series)" do
      closes = Array.new(20, 100.0)
      expect(described_class.rsi(closes)).to eq(50.0)
    end

    it "returns a value below 30 for a steadily declining series (oversold zone)" do
      closes = (1..20).map { |i| 100.0 - i * 2 }
      rsi = described_class.rsi(closes)
      expect(rsi).to be < 30.0
    end

    it "respects custom period" do
      closes = (1..30).map(&:to_f)
      expect(described_class.rsi(closes, period: 7)).to eq(100.0)
    end
  end

  describe ".sma" do
    it "returns nil when there are fewer than period closes" do
      expect(described_class.sma((1..49).map(&:to_f), period: 50)).to be_nil
    end

    it "computes a simple mean of the last `period` closes" do
      closes = (1..50).map(&:to_f) # 1..50
      # SMA(50) of 1..50 = (1+50)*50/2 / 50 = 25.5
      expect(described_class.sma(closes, period: 50)).to eq(25.5)
    end

    it "uses only the trailing window when more data is provided" do
      closes = ((1..100).map { |i| i.to_f })
      # SMA(50) of last 50 (51..100) = (51+100)*50/2 / 50 = 75.5
      expect(described_class.sma(closes, period: 50)).to eq(75.5)
    end
  end

  describe ".bollinger_bands" do
    it "returns nil with fewer than period closes" do
      expect(described_class.bollinger_bands((1..19).map(&:to_f))).to be_nil
    end

    it "produces middle = SMA(period) and upper/lower symmetric around it" do
      closes = (1..20).map(&:to_f)
      bands = described_class.bollinger_bands(closes)
      expect(bands[:middle]).to eq(10.5)
      expect(bands[:upper] - bands[:middle]).to be_within(0.0001).of(bands[:middle] - bands[:lower])
    end

    it "collapses upper == middle == lower for a flat series" do
      closes = Array.new(20, 100.0)
      bands = described_class.bollinger_bands(closes)
      expect(bands[:upper]).to eq(100.0)
      expect(bands[:middle]).to eq(100.0)
      expect(bands[:lower]).to eq(100.0)
    end

    it "respects custom period and stddev" do
      closes = (1..30).map(&:to_f)
      bands_default = described_class.bollinger_bands(closes, period: 20, stddev: 2.0)
      bands_tighter = described_class.bollinger_bands(closes, period: 20, stddev: 1.0)
      expect(bands_default[:upper]).to be > bands_tighter[:upper]
      expect(bands_default[:lower]).to be < bands_tighter[:lower]
    end
  end
end
