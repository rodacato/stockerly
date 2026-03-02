require "rails_helper"

RSpec.describe Trading::Domain::TimeWeightedReturn do
  # Helper to create snapshot-like objects
  TwrSnapshot = Data.define(:date, :total_value, :invested_value)

  describe "#calculate" do
    context "with fewer than 2 snapshots" do
      it "returns zero for empty input" do
        result = described_class.new(snapshots: []).calculate
        expect(result).to be_zero
      end

      it "returns zero for a single snapshot" do
        snap = TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 10_000, invested_value: 10_000)
        result = described_class.new(snapshots: [ snap ]).calculate
        expect(result).to be_zero
      end
    end

    context "with simple growth (no cash flows)" do
      it "calculates correct TWR for steady growth" do
        snapshots = [
          TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 10_000, invested_value: 10_000),
          TwrSnapshot.new(date: Date.new(2026, 1, 2), total_value: 10_500, invested_value: 10_000),
          TwrSnapshot.new(date: Date.new(2026, 1, 3), total_value: 11_025, invested_value: 10_000)
        ]

        result = described_class.new(snapshots: snapshots).calculate

        # R1 = (10500 - 10000) / 10000 = 0.05
        # R2 = (11025 - 10500) / 10500 = 0.05
        # TWR = (1.05 * 1.05 - 1) * 100 = 10.25%
        expect(result.percent).to eq(10.25)
        expect(result.absolute).to eq(1025.0)
        expect(result).to be_positive
      end
    end

    context "with a deposit (positive cash flow)" do
      it "eliminates cash flow effect from returns" do
        snapshots = [
          TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 10_000, invested_value: 10_000),
          TwrSnapshot.new(date: Date.new(2026, 1, 2), total_value: 15_500, invested_value: 15_000)
          # V_end=15500, V_start=10000, CF=5000 (deposit)
          # R = (15500 - 10000 - 5000) / 10000 = 0.05 = 5%
        ]

        result = described_class.new(snapshots: snapshots).calculate

        expect(result.percent).to eq(5.0)
        expect(result.absolute).to eq(5500.0)
      end
    end

    context "with a withdrawal (negative cash flow)" do
      it "eliminates cash flow effect from returns" do
        snapshots = [
          TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 10_000, invested_value: 10_000),
          TwrSnapshot.new(date: Date.new(2026, 1, 2), total_value: 7_350, invested_value: 7_000)
          # V_end=7350, V_start=10000, CF=-3000 (withdrawal)
          # R = (7350 - 10000 - (-3000)) / 10000 = 0.035 = 3.5%
        ]

        result = described_class.new(snapshots: snapshots).calculate

        expect(result.percent).to eq(3.5)
      end
    end

    context "with a flat portfolio" do
      it "returns zero percent" do
        snapshots = [
          TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 10_000, invested_value: 10_000),
          TwrSnapshot.new(date: Date.new(2026, 1, 2), total_value: 10_000, invested_value: 10_000)
        ]

        result = described_class.new(snapshots: snapshots).calculate

        expect(result.percent).to eq(0.0)
        expect(result).to be_zero
      end
    end

    context "with a loss" do
      it "returns negative percent" do
        snapshots = [
          TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 10_000, invested_value: 10_000),
          TwrSnapshot.new(date: Date.new(2026, 1, 2), total_value: 9_500, invested_value: 10_000)
        ]

        result = described_class.new(snapshots: snapshots).calculate

        expect(result.percent).to eq(-5.0)
        expect(result).to be_negative
      end
    end

    context "with multi-period chaining" do
      it "chains sub-period returns multiplicatively" do
        snapshots = [
          TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 10_000, invested_value: 10_000),
          TwrSnapshot.new(date: Date.new(2026, 1, 2), total_value: 11_000, invested_value: 10_000),  # +10%
          TwrSnapshot.new(date: Date.new(2026, 1, 3), total_value: 9_900, invested_value: 10_000)     # -10%
        ]

        result = described_class.new(snapshots: snapshots).calculate

        # (1.10 * 0.90 - 1) * 100 = -1.0%
        expect(result.percent).to eq(-1.0)
      end
    end

    context "with unsorted snapshots" do
      it "sorts by date before calculating" do
        snapshots = [
          TwrSnapshot.new(date: Date.new(2026, 1, 3), total_value: 11_025, invested_value: 10_000),
          TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 10_000, invested_value: 10_000),
          TwrSnapshot.new(date: Date.new(2026, 1, 2), total_value: 10_500, invested_value: 10_000)
        ]

        result = described_class.new(snapshots: snapshots).calculate

        expect(result.percent).to eq(10.25)
      end
    end

    context "with zero starting value" do
      it "handles gracefully without division by zero" do
        snapshots = [
          TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 0, invested_value: 0),
          TwrSnapshot.new(date: Date.new(2026, 1, 2), total_value: 10_000, invested_value: 10_000)
        ]

        result = described_class.new(snapshots: snapshots).calculate

        expect(result.percent).to eq(0.0)
      end
    end
  end

  describe "#annualized" do
    it "annualizes the TWR over the snapshot period" do
      snapshots = [
        TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 10_000, invested_value: 10_000),
        TwrSnapshot.new(date: Date.new(2026, 7, 1), total_value: 10_500, invested_value: 10_000)
        # 181 days, 5% return
        # Annualized = (1.05)^(365/181) - 1
      ]

      result = described_class.new(snapshots: snapshots).annualized

      expected = ((1.05)**(365.0 / 181) - 1) * 100
      expect(result.percent).to be_within(0.1).of(expected)
      expect(result.absolute).to eq(500.0)
    end

    it "returns zero for flat portfolio" do
      snapshots = [
        TwrSnapshot.new(date: Date.new(2026, 1, 1), total_value: 10_000, invested_value: 10_000),
        TwrSnapshot.new(date: Date.new(2026, 7, 1), total_value: 10_000, invested_value: 10_000)
      ]

      result = described_class.new(snapshots: snapshots).annualized

      expect(result).to be_zero
    end
  end
end
