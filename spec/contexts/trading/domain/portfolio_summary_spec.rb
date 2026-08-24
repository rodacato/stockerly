require "rails_helper"

RSpec.describe Trading::Domain::PortfolioSummary do
  let(:user) { create(:user) }
  let(:portfolio) { create(:portfolio, user: user) }
  let(:asset_usd) { create(:asset, current_price: 150.0, sector: "Technology") }
  let(:asset_intl) { create(:asset, symbol: "GENIUSSACV.MX", current_price: 80.0, sector: "Technology") }

  before do
    create(:position, portfolio: portfolio, asset: asset_usd, shares: 10, avg_cost: 100.0)
    create(:position, portfolio: portfolio, asset: asset_intl, shares: 20, avg_cost: 60.0)
  end

  subject { Trading::Domain::PortfolioSummary.new(portfolio) }

  describe "#total_value" do
    it "returns the sum of open position market values" do
      # (10 * 150) + (20 * 80) = 1500 + 1600
      expect(subject.total_value).to eq(3100.0)
    end
  end

  describe "#unrealized_gain" do
    it "returns GainLoss with total unrealized gain" do
      result = subject.unrealized_gain
      # USD: 10 * (150 - 100) = 500, MXN: 20 * (80 - 60) = 400 => 900
      expect(result).to be_a(GainLoss)
      expect(result.absolute).to eq(900.0)
      expect(result).to be_positive
    end
  end

  describe "#day_gain" do
    it "returns zero GainLoss when no yesterday snapshot" do
      result = subject.day_gain
      expect(result.absolute).to eq(0.0)
      expect(result.percent).to eq(0.0)
    end

    it "calculates day gain from yesterday snapshot" do
      create(:portfolio_snapshot, portfolio: portfolio, date: Date.yesterday, total_value: 2800.0, invested_value: 2800.0)

      result = subject.day_gain
      # today: 3100 - yesterday: 2800 = 300
      expect(result.absolute).to eq(300.0)
      expect(result.percent).to be_within(0.01).of(10.71)
    end
  end

  describe "#total_invested" do
    it "sums cost basis of open positions" do
      # USD: 10 * 100 = 1000, MXN: 20 * 60 = 1200 => 2200
      expect(subject.total_invested).to eq(2200.0)
    end
  end

  describe "#to_h" do
    it "returns all summary data as a hash" do
      hash = subject.to_h
      expect(hash).to have_key(:total_value)
      expect(hash).to have_key(:unrealized_gain)
      expect(hash).to have_key(:day_gain)
      expect(hash).to have_key(:total_invested)
    end
  end
end
