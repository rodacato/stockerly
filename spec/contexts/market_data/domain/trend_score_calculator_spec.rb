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
        expect(result[:label]).to be_in(%i[moderate high_score peak])
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
        expect(result[:label]).to be_in(%i[low_score low_moderate])
      end
    end

    context "with flat prices" do
      let(:closes) do
        Array.new(20) { 150.0 }
      end

      it "returns a neutral score with upward direction (momentum = 0)" do
        result = described_class.calculate(closes: closes)

        expect(result).to be_a(Hash)
        expect(result[:score]).to be_between(40, 60)
        expect(result[:direction]).to eq(:upward)
        expect(result[:label]).to eq(:neutral)
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

        expect(result[:label]).to be_in(%i[low_score low_moderate neutral moderate high_score peak])
      end
    end

    context "per-factor gating" do
      let(:uptrend_closes) { (1..40).map { |i| 100.0 + (i * 1.5) } }
      let(:uptrend_volumes) { (1..40).map { |i| 1_000_000 + (i * 10_000) } }

      it "returns factors hash with all 5 keys" do
        result = described_class.calculate(closes: uptrend_closes, volumes: uptrend_volumes)

        expect(result[:factors]).to be_a(Hash)
        expect(result[:factors].keys).to contain_exactly(:rsi, :momentum, :macd, :volume_trend, :ema_crossover)
        result[:factors].each_value { |v| expect(v).to be_a(Float) }
      end

      it "yields every factor the series can support, not only the two a short series used to allow" do
        closes = (1..25).map { |i| 100.0 + (i * 1.0) }
        result = described_class.calculate(closes: closes)

        # 25 closes clears ema_crossover (21) but not macd (34). The old ">= 35"
        # branch withheld all three behind the strictest one's requirement.
        expect(result[:factors].keys).to contain_exactly(:rsi, :momentum, :ema_crossover)
      end

      it "adds volume_trend once there are enough volumes, still short of macd" do
        closes = (1..25).map { |i| 100.0 + (i * 1.0) }
        result = described_class.calculate(closes: closes, volumes: Array.new(25, 1_000_000))

        expect(result[:factors].keys).to contain_exactly(:rsi, :momentum, :ema_crossover, :volume_trend)
      end

      it "drops a missing volume rather than scoring it as no trading" do
        closes = (1..40).map { |i| 100.0 + i }
        steady = Array.new(40, 1_000_000)
        with_gaps = steady.dup
        [ 5, 12, 27 ].each { |i| with_gaps[i] = nil }

        intact = described_class.calculate(closes: closes, volumes: steady)
        gapped = described_class.calculate(closes: closes, volumes: with_gaps)

        expect(gapped[:factors][:volume_trend]).to eq(intact[:factors][:volume_trend])
      end

      it "would have been dragged down had the gaps been scored as zero" do
        closes = (1..40).map { |i| 100.0 + i }
        zeroed = Array.new(40, 1_000_000)
        [ 36, 37, 38 ].each { |i| zeroed[i] = 0.0 }

        honest = described_class.calculate(closes: closes, volumes: Array.new(40, 1_000_000))
        with_zeros = described_class.calculate(closes: closes, volumes: zeroed)

        expect(with_zeros[:factors][:volume_trend]).to be < honest[:factors][:volume_trend]
      end

      it "withholds the factor when too few volumes were actually reported" do
        closes = (1..40).map { |i| 100.0 + i }
        mostly_missing = Array.new(40) { |i| i < 25 ? nil : 1_000_000 }

        result = described_class.calculate(closes: closes, volumes: mostly_missing)

        expect(result[:factors]).not_to have_key(:volume_trend)
      end

      it "never reports macd below the closes EMA26 needs to seed" do
        (15..33).each do |n|
          result = described_class.calculate(closes: (1..n).map { |i| 100.0 + i })
          expect(result[:factors]).not_to have_key(:macd), "macd appeared with #{n} closes"
        end
      end

      it "scores a partial reading rather than refusing one" do
        result = described_class.calculate(closes: (1..25).map { |i| 100.0 + i })

        expect(result[:score]).to be_between(0, 100)
        expect(described_class::FACTORS - result[:factors].keys).to contain_exactly(:macd, :volume_trend)
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

  context "characterisation of the arithmetic behind each factor" do
    let(:sawtooth) { (1..40).map { |i| 100.0 + (i * 0.5) + (i.even? ? 1.5 : -1.5) } }
    let(:linear_up) { (1..40).map { |i| 100.0 + (i * 1.5) } }
    let(:gentle_up) { (1..40).map { |i| 100.0 + (i * 0.2) } }
    let(:gentle_down) { (1..40).map { |i| 200.0 - (i * 0.2) } }
    let(:steep_down) { (1..40).map { |i| 200.0 - (i * 1.5) } }
    let(:accelerating) { (1..40).map { |i| 100.0 + (i * 0.5) + (i > 25 ? (i - 25) * 3.0 : 0) } }
    let(:spiking_volumes) { Array.new(35, 1_000_000) + Array.new(5, 3_000_000) }

    describe "compute_ema_series" do
      it "seeds on the mean of the first period values, which a seed taken from values.first would not match" do
        series = described_class.send(:compute_ema_series, (1..15).map(&:to_f), 5)

        expect(series.size).to eq(11)
        series.zip((3..13).map(&:to_f)).each do |got, expected|
          expect(got).to be_within(1e-9).of(expected)
        end
      end

      it "returns the seed alone when the series is exactly one period long, catching an off-by-one in the guard" do
        expect(described_class.send(:compute_ema_series, (1..12).map(&:to_f), 12)).to eq([ 6.5 ])
      end

      it "returns an empty array one value short of the period, not the nil its callers would crash on" do
        expect(described_class.send(:compute_ema_series, (1..11).map(&:to_f), 12)).to eq([])
      end

      it "emits one value per input past the seed window, which is what MACD's alignment offset assumes" do
        expect(described_class.send(:compute_ema_series, (1..40).map(&:to_f), 26).size).to eq(15)
        expect(described_class.send(:compute_ema_series, (1..40).map(&:to_f), 12).size).to eq(29)
      end
    end

    describe "rsi_14" do
      it "divides average gain by average loss when the window holds both, the branch no other spec reaches" do
        expect(described_class.send(:rsi_14, sawtooth)).to eq(58.33)
      end

      it "keeps the three early returns that a single general formula would turn into NaN or Infinity" do
        expect(described_class.send(:rsi_14, Array.new(20, 150.0))).to eq(50.0)
        expect(described_class.send(:rsi_14, (1..20).map { |i| 100.0 + i })).to eq(100.0)
        expect(described_class.send(:rsi_14, (1..20).map { |i| 200.0 - i })).to eq(0.0)
      end

      it "reads only the last 15 closes, so history before the window cannot move the answer" do
        expect(described_class.send(:rsi_14, Array.new(25, 1.0) + sawtooth)).to eq(58.33)
      end
    end

    describe "macd_signal" do
      it "pins the histogram-to-score scale on a series whose histogram is not zero" do
        expect(described_class.send(:macd_signal, sawtooth)).to be_within(1e-9).of(50.436997288702344)
      end

      it "pins the exact value the accelerating-uptrend example only bounds at >= 50" do
        expect(described_class.send(:macd_signal, accelerating)).to be_within(1e-9).of(68.29558130666342)
      end

      it "lands on the midpoint for a linear series, which a wrong EMA alignment offset would shift" do
        expect(described_class.send(:macd_signal, linear_up)).to be_within(1e-9).of(50.0)
      end
    end

    describe "ema_crossover" do
      it "pins the spread-to-score scale either side of the midpoint, where the clamp hides it today" do
        expect(described_class.send(:ema_crossover, gentle_up)).to be_within(1e-9).of(61.111111111111114)
        expect(described_class.send(:ema_crossover, gentle_down)).to be_within(1e-9).of(43.75)
      end

      it "pins the unsaturated value the sawtooth produces" do
        expect(described_class.send(:ema_crossover, sawtooth)).to be_within(1e-9).of(75.47521066039579)
      end

      it "records that the strong uptrend the suite asserts on sits at the clamp ceiling, not in the linear region" do
        expect(described_class.send(:ema_crossover, linear_up)).to eq(100.0)
      end
    end

    describe "volume_trend" do
      it "inverts the ratio when momentum is negative, a 100-point swing on identical volumes" do
        expect(described_class.send(:volume_trend, spiking_volumes, 7.02)).to eq(100.0)
        expect(described_class.send(:volume_trend, spiking_volumes, -6.98)).to eq(0.0)
      end

      it "scores steady volume at a third of the range, not at a neutral midpoint" do
        expect(described_class.send(:volume_trend, Array.new(40, 1_000_000), 5.0)).to be_within(1e-9).of(33.333333333333336)
      end

      it "answers the midpoint instead of dividing by a zero 20-day average" do
        expect(described_class.send(:volume_trend, Array.new(40, 0), 5.0)).to eq(50.0)
      end
    end

    describe "blend_5_factor" do
      it "renormalises over the weights actually present instead of over a fixed 1.0" do
        expect(described_class.send(:blend_5_factor, 70.0, 5.0, nil, nil, nil)).to eq(67)
      end

      it "pins the five-factor blend that the 0.6/0.4 example name describes but never computes" do
        expect(described_class.send(:blend_5_factor, 70.0, 5.0, 60.0, 40.0, 55.0)).to eq(60)
      end

      it "weights macd above volume and the ema crossover, a difference a uniform weight would flatten" do
        expect(described_class.send(:blend_5_factor, 0.0, -20.0, 100.0, nil, nil)).to eq(29)
        expect(described_class.send(:blend_5_factor, 0.0, -20.0, nil, 100.0, nil)).to eq(23)
        expect(described_class.send(:blend_5_factor, 0.0, -20.0, nil, nil, 100.0)).to eq(23)
      end
    end

    describe ".calculate" do
      it "pins the whole reading for a series that saturates no factor" do
        result = described_class.calculate(closes: sawtooth, volumes: Array.new(40, 1_000_000))

        expect(result).to eq(
          score: 57,
          label: :neutral,
          direction: :upward,
          factors: { rsi: 58.3, momentum: 64.1, macd: 50.4, volume_trend: 33.3, ema_crossover: 75.5 }
        )
      end

      it "pins the bearish reading, where the same volume spike counts against the score" do
        result = described_class.calculate(closes: steep_down, volumes: spiking_volumes)

        expect(result).to eq(
          score: 17,
          label: :low_score,
          direction: :downward,
          factors: { rsi: 0.0, momentum: 32.6, macd: 50.0, volume_trend: 0.0, ema_crossover: 0.0 }
        )
      end
    end
  end
end
