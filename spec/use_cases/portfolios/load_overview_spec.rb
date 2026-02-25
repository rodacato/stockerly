require "rails_helper"

RSpec.describe Portfolios::LoadOverview do
  let(:user) { create(:user) }
  let!(:portfolio) { create(:portfolio, user: user, buying_power: 5000.0) }
  let(:asset) { create(:asset, current_price: 150.0, sector: "Technology") }

  describe ".call" do
    it "returns Success with portfolio data" do
      result = described_class.call(user: user)

      expect(result).to be_success
      data = result.value!
      expect(data[:portfolio]).to eq(portfolio)
      expect(data[:summary]).to be_a(PortfolioSummary)
      expect(data[:tab]).to eq("open")
    end

    it "returns Failure when no portfolio" do
      portfolio.destroy
      result = described_class.call(user: user.reload)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:not_found)
    end

    it "loads open positions by default" do
      create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100.0, status: :open)
      create(:position, portfolio: portfolio, asset: create(:asset, symbol: "CL"), shares: 5, avg_cost: 50.0, status: :closed)

      result = described_class.call(user: user, tab: "open")
      expect(result.value![:positions].count).to eq(1)
    end

    it "loads closed positions when tab=closed" do
      create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100.0, status: :closed)

      result = described_class.call(user: user, tab: "closed")
      expect(result.value![:positions].count).to eq(1)
    end

    it "loads dividend payments when tab=dividends" do
      dividend = create(:dividend, asset: asset)
      create(:dividend_payment, portfolio: portfolio, dividend: dividend)

      result = described_class.call(user: user, tab: "dividends")
      expect(result.value![:positions].count).to eq(1)
    end

    it "returns allocation by sector" do
      create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100.0)

      result = described_class.call(user: user)
      allocation = result.value![:allocation]
      expect(allocation).to be_a(Hash)
    end

    it "includes period returns and chart data" do
      result = described_class.call(user: user)
      data = result.value!

      expect(data[:period_returns]).to be_a(Hash)
      expect(data[:period_returns].keys).to include("1M", "ALL")
      expect(data[:chart_data]).to be_an(Array)
    end
  end
end
