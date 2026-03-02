require "rails_helper"

RSpec.describe Trading::PortfolioSummary do
  let(:user) { create(:user) }
  let(:portfolio) { create(:portfolio, user: user, buying_power: 5000.0) }
  let(:asset_usd) { create(:asset, current_price: 150.0, sector: "Technology") }
  let(:asset_intl) { create(:asset, symbol: "GENIUSSACV.MX", current_price: 80.0, sector: "Technology") }

  before do
    create(:position, portfolio: portfolio, asset: asset_usd, shares: 10, avg_cost: 100.0, currency: "USD")
    create(:position, portfolio: portfolio, asset: asset_intl, shares: 20, avg_cost: 60.0, currency: "MXN")
  end

  subject { Trading::PortfolioSummary.new(portfolio) }

  describe "#total_value" do
    it "returns sum of open positions market value plus buying power" do
      # (10 * 150) + (20 * 80) + 5000 = 1500 + 1600 + 5000 = 8100
      expect(subject.total_value).to eq(8100.0)
    end
  end

  describe "#buying_power" do
    it "returns portfolio buying power" do
      expect(subject.buying_power).to eq(5000.0)
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
      create(:portfolio_snapshot, portfolio: portfolio, date: Date.yesterday, total_value: 7800.0, cash_value: 5000.0, invested_value: 2800.0)

      result = subject.day_gain
      # today: 8100 - yesterday: 7800 = 300
      expect(result.absolute).to eq(300.0)
      expect(result.percent).to be_within(0.01).of(3.85)
    end
  end

  describe "#domestic_value" do
    it "sums market value of USD positions" do
      expect(subject.domestic_value).to eq(1500.0)
    end
  end

  describe "#international_value" do
    it "sums market value of non-USD positions" do
      expect(subject.international_value).to eq(1600.0)
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
      expect(hash).to have_key(:buying_power)
      expect(hash).to have_key(:unrealized_gain)
      expect(hash).to have_key(:day_gain)
      expect(hash).to have_key(:domestic_value)
      expect(hash).to have_key(:international_value)
      expect(hash).to have_key(:total_invested)
    end
  end
end
