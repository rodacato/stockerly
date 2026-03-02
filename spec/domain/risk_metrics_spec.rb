require "rails_helper"

RSpec.describe RiskMetrics do
  subject(:metrics) { described_class.new(volatility: vol, sharpe_ratio: sharpe, max_drawdown: dd, has_sufficient_data: true) }

  let(:vol) { 0.15 }
  let(:sharpe) { 0.8 }
  let(:dd) { 0.12 }

  describe "#high_volatility?" do
    it "returns true when volatility > 25%" do
      m = described_class.new(volatility: 0.30, sharpe_ratio: 0.0, max_drawdown: 0.0, has_sufficient_data: true)
      expect(m.high_volatility?).to be true
    end

    it "returns false when volatility <= 25%" do
      expect(metrics.high_volatility?).to be false
    end
  end

  describe "#low_volatility?" do
    it "returns true when volatility < 10%" do
      m = described_class.new(volatility: 0.08, sharpe_ratio: 0.0, max_drawdown: 0.0, has_sufficient_data: true)
      expect(m.low_volatility?).to be true
    end

    it "returns false when volatility >= 10%" do
      expect(metrics.low_volatility?).to be false
    end
  end

  describe "#sharpe_label" do
    it "returns 'Good' for sharpe >= 1.0" do
      m = described_class.new(volatility: 0.0, sharpe_ratio: 1.2, max_drawdown: 0.0, has_sufficient_data: true)
      expect(m.sharpe_label).to eq("Good")
    end

    it "returns 'Acceptable' for sharpe 0.5..1.0" do
      expect(metrics.sharpe_label).to eq("Acceptable")
    end

    it "returns 'Low' for sharpe 0.0..0.5" do
      m = described_class.new(volatility: 0.0, sharpe_ratio: 0.3, max_drawdown: 0.0, has_sufficient_data: true)
      expect(m.sharpe_label).to eq("Low")
    end

    it "returns 'Negative' for sharpe < 0" do
      m = described_class.new(volatility: 0.0, sharpe_ratio: -0.5, max_drawdown: 0.0, has_sufficient_data: true)
      expect(m.sharpe_label).to eq("Negative")
    end
  end
end
