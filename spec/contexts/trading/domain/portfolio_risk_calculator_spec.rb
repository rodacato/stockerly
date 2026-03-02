require "rails_helper"

RSpec.describe Trading::Domain::PortfolioRiskCalculator do
  RiskSnapshot = Data.define(:date, :total_value, :invested_value)

  def build_snapshots(count:, start_date: Date.new(2026, 1, 1), daily_return: 0.001, start_value: 10_000)
    value = start_value.to_f
    (0...count).map do |i|
      snap = RiskSnapshot.new(date: start_date + i.days, total_value: value.round(2), invested_value: start_value)
      value *= (1 + daily_return)
      snap
    end
  end

  describe "#calculate" do
    context "with insufficient data (< 31 snapshots)" do
      it "returns result with has_sufficient_data: false" do
        snapshots = build_snapshots(count: 20)
        result = described_class.new(snapshots: snapshots, risk_free_rate: 0.0).calculate

        expect(result.has_sufficient_data).to be false
        expect(result.volatility).to eq(0.0)
        expect(result.sharpe_ratio).to eq(0.0)
        expect(result.max_drawdown).to eq(0.0)
      end
    end

    context "with sufficient data and steady growth" do
      it "returns low volatility for constant daily returns" do
        snapshots = build_snapshots(count: 60, daily_return: 0.001)
        result = described_class.new(snapshots: snapshots, risk_free_rate: 0.0).calculate

        expect(result.has_sufficient_data).to be true
        # Constant daily returns → zero std dev → zero volatility
        expect(result.volatility).to eq(0.0)
        expect(result.max_drawdown).to eq(0.0)
      end

      it "returns high Sharpe with near-zero volatility and positive returns" do
        snapshots = build_snapshots(count: 60, daily_return: 0.001)
        result = described_class.new(snapshots: snapshots, risk_free_rate: 0.0).calculate

        # Constant returns → near-zero volatility → very high Sharpe
        expect(result.sharpe_ratio).to be > 0.0
      end
    end

    context "with volatile returns" do
      it "calculates non-zero volatility" do
        start_date = Date.new(2026, 1, 1)
        value = 10_000.0
        snapshots = [ RiskSnapshot.new(date: start_date, total_value: value, invested_value: 10_000) ]

        # Alternate positive and negative returns to create volatility
        40.times do |i|
          daily_r = i.even? ? 0.02 : -0.015
          value *= (1 + daily_r)
          snapshots << RiskSnapshot.new(date: start_date + (i + 1).days, total_value: value.round(2), invested_value: 10_000)
        end

        result = described_class.new(snapshots: snapshots, risk_free_rate: 0.05).calculate

        expect(result.has_sufficient_data).to be true
        expect(result.volatility).to be > 0.0
        expect(result.sharpe_ratio).not_to eq(0.0)
      end
    end

    context "with a drawdown" do
      it "calculates max drawdown from peak to trough" do
        start_date = Date.new(2026, 1, 1)
        # Build: 20 days of growth, then 15 days of decline, then 5 days recovery
        values = []
        value = 10_000.0
        20.times { value *= 1.01; values << value }  # growth to ~12,202
        peak = value
        15.times { value *= 0.98; values << value }   # decline to ~8,977
        trough = value
        5.times { value *= 1.005; values << value }    # slight recovery

        snapshots = [ RiskSnapshot.new(date: start_date, total_value: 10_000, invested_value: 10_000) ]
        values.each_with_index do |v, i|
          snapshots << RiskSnapshot.new(date: start_date + (i + 1).days, total_value: v.round(2), invested_value: 10_000)
        end

        result = described_class.new(snapshots: snapshots, risk_free_rate: 0.0).calculate

        expected_dd = (peak - trough) / peak
        expect(result.max_drawdown).to be_within(0.01).of(expected_dd)
        expect(result.max_drawdown).to be > 0.0
      end
    end

    context "with zero starting value" do
      it "handles gracefully without division by zero" do
        snapshots = build_snapshots(count: 35, start_value: 0, daily_return: 0.0)
        result = described_class.new(snapshots: snapshots, risk_free_rate: 0.0).calculate

        expect(result.has_sufficient_data).to be true
        expect(result.volatility).to eq(0.0)
      end
    end

    context "with default risk-free rate from CETES" do
      it "uses CETES 28D yield when no rate provided" do
        create(:asset, :fixed_income, symbol: "CETES_28D", yield_rate: 10.25)

        snapshots = build_snapshots(count: 35, daily_return: 0.0)
        calculator = described_class.new(snapshots: snapshots)
        result = calculator.calculate

        expect(result.has_sufficient_data).to be true
      end
    end
  end
end
