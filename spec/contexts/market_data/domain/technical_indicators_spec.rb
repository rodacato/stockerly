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
      closes = (1..20).map { |i| 100.0 - (i * 2) }
      rsi = described_class.rsi(closes)
      expect(rsi).to be < 30.0
    end

    it "divides average gain by average loss when the window holds both, the branch the three constants never reach" do
      closes = (1..40).map { |i| 100.0 + (i * 0.5) + (i.even? ? 1.5 : -1.5) }

      expect(described_class.rsi(closes)).to eq(60.4)
    end

    it "smooths across the series, so closes before the last window still move the answer" do
      recent = (1..40).map { |i| 100.0 + (i * 0.5) + (i.even? ? 1.5 : -1.5) }

      expect(described_class.rsi(Array.new(25, 1.0) + recent)).to eq(65.09)
    end

    it "respects custom period" do
      closes = (1..30).map(&:to_f)
      expect(described_class.rsi(closes, period: 7)).to eq(100.0)
    end
  end

  describe ".current_reading" do
    let(:closes) { (1..220).map { |i| 100.0 + (i * 0.5) } }
    let(:bars) { Array.new(30) { |i| { high: 11.0 + i, low: 9.0 + i, close: 10.0 + i } } }

    it "carries an ATR only when it was given bars to compute one from" do
      expect(described_class.current_reading(closes)).not_to have_key(:atr)
      expect(described_class.current_reading(closes, bars: bars)[:atr]).to be_a(Float)
    end

    it "reports every key it could compute and none it could not" do
      reading = described_class.current_reading(closes, bars: bars)

      expect(described_class::READINGS - reading.keys).to be_empty
    end

    it "withholds the averages a short series cannot support rather than zeroing them" do
      reading = described_class.current_reading((1..60).map(&:to_f), bars: bars)

      expect(reading).to have_key(:sma_50)
      expect(reading).not_to have_key(:sma_200)
    end
  end

  describe ".atr" do
    def bar(high, low, close) = { high: high, low: low, close: close }

    # One point of range a day, but each session opens a point and a half above
    # the last close. Bollinger's deviation of closes cannot see that gap.
    let(:gapping) { Array.new(30) { |i| bar(10.0 + i, 9.0 + i, 9.5 + i) } }
    let(:widening) { Array.new(40) { |i| bar(100.0 + (i * 2), 100.0 - (i * 0.5), 100.0 + i) } }

    it "is nil, never zero, below the bars its period needs" do
      expect(described_class.atr(Array.new(14) { bar(11.0, 9.0, 10.0) })).to be_nil
    end

    it "returns the range itself when every session has the same one" do
      expect(described_class.atr(Array.new(30) { bar(11.0, 9.0, 10.0) })).to eq(2.0)
    end

    it "counts the gap between sessions, not only the range inside one" do
      # Every bar spans exactly 1.0; the answer is 1.5 because the open gaps.
      expect(described_class.atr(gapping)).to eq(1.5)
    end

    it "smooths by Wilder's recursion rather than averaging the window" do
      # 67.5482 from the recursion; a plain mean of the last fourteen true
      # ranges gives 81.25 on the same bars.
      expect(described_class.atr(widening)).to eq(67.5482)
    end

    it "applies one more step of the recursion for one more bar" do
      before_last = described_class.atr(widening[0..-2])
      last = widening.last(2)
      range = [ last[1][:high] - last[1][:low],
                (last[1][:high] - last[0][:close]).abs,
                (last[1][:low] - last[0][:close]).abs ].max

      expect(described_class.atr(widening)).to eq((((before_last * 13) + range) / 14.0).round(4))
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
