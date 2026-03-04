require "rails_helper"

RSpec.describe Trading::Domain::ConcentrationAnalyzer do
  let(:user) { create(:user) }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  describe ".analyze" do
    it "returns empty result for portfolio with no open positions" do
      result = described_class.analyze(portfolio: portfolio)

      expect(result.has_data).to be false
      expect(result.hhi).to eq(0)
      expect(result.risk_level).to eq(:low)
      expect(result.position_count).to eq(0)
    end

    it "returns HHI of 10000 and high risk for single-position portfolio" do
      asset = create(:asset, symbol: "AAPL", current_price: 150.0, sector: "Technology")
      create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)

      result = described_class.analyze(portfolio: portfolio)

      expect(result.has_data).to be true
      expect(result.hhi).to eq(10_000)
      expect(result.risk_level).to eq(:high)
      expect(result.max_position_symbol).to eq("AAPL")
      expect(result.max_position_pct).to eq(100.0)
    end

    it "returns low HHI and low risk for evenly distributed 10-position portfolio" do
      10.times do |i|
        asset = create(:asset, symbol: "S#{i}", current_price: 100.0, sector: "Sector#{i}")
        create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
      end

      result = described_class.analyze(portfolio: portfolio)

      expect(result.hhi).to eq(1000)
      expect(result.risk_level).to eq(:low)
      expect(result.max_position_pct).to eq(10.0)
    end

    it "returns high HHI for concentrated two-position portfolio" do
      asset1 = create(:asset, symbol: "BIG", current_price: 90.0, sector: "Tech")
      asset2 = create(:asset, symbol: "SML", current_price: 10.0, sector: "Health")
      create(:position, portfolio: portfolio, asset: asset1, shares: 1, status: :open)
      create(:position, portfolio: portfolio, asset: asset2, shares: 1, status: :open)

      result = described_class.analyze(portfolio: portfolio)

      # 90% and 10% → HHI = 0.9² + 0.1² = 0.82 × 10000 = 8200
      expect(result.hhi).to be > 2500
      expect(result.risk_level).to eq(:high)
    end

    it "returns high risk when one sector exceeds 60%" do
      3.times do |i|
        asset = create(:asset, symbol: "T#{i}", current_price: 100.0, sector: "Technology")
        create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
      end
      asset_other = create(:asset, symbol: "H1", current_price: 100.0, sector: "Healthcare")
      create(:position, portfolio: portfolio, asset: asset_other, shares: 10, status: :open)

      result = described_class.analyze(portfolio: portfolio)

      expect(result.max_sector_pct).to eq(75.0)
      expect(result.risk_level).to eq(:high)
    end

    it "returns moderate risk when single position is at 30%" do
      big = create(:asset, symbol: "BIG", current_price: 300.0, sector: "Tech")
      create(:position, portfolio: portfolio, asset: big, shares: 1, status: :open)
      7.times do |i|
        asset = create(:asset, symbol: "X#{i}", current_price: 100.0, sector: "Sector#{i}")
        create(:position, portfolio: portfolio, asset: asset, shares: 1, status: :open)
      end

      result = described_class.analyze(portfolio: portfolio)

      expect(result.max_position_pct).to eq(30.0)
      expect(result.risk_level).to eq(:moderate)
    end
  end
end
