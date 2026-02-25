require "rails_helper"

RSpec.describe "Interactive chart tooltips", type: :request do
  let!(:user) { create(:user, email: "chart@example.com", password: "password123") }

  before { login_as(user) }

  describe "Price chart on asset detail page (SVG fallback)" do
    # TradingView replaces SVG chart for stocks/etf/crypto — use index for SVG tooltip tests
    let!(:asset) { create(:asset, symbol: "SPX", name: "S&P 500", asset_type: :index, current_price: 5200.0) }

    before do
      5.times do |i|
        create(:asset_price_history, asset: asset, date: (5 - i).days.ago.to_date, close: 10.5 + i * 0.1)
      end
    end

    it "renders circle elements with data-date and data-value for tooltip interaction" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="chart-tooltip"')
      expect(response.body).to include('data-chart-tooltip-target="svg"')
      expect(response.body).to include('data-date=')
      expect(response.body).to include('data-value=')
    end

    it "renders tooltip target div" do
      get market_asset_path(asset.symbol)

      expect(response.body).to include('data-chart-tooltip-target="tooltip"')
    end
  end

  describe "Portfolio performance chart" do
    let!(:portfolio) { create(:portfolio, user: user) }

    before do
      5.times do |i|
        create(:portfolio_snapshot, portfolio: portfolio, date: (5 - i).days.ago.to_date, total_value: 10_000 + i * 500)
      end
    end

    it "renders circle data points for tooltip interaction" do
      get portfolio_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="chart-tooltip"')
      expect(response.body).to include('data-chart-tooltip-target="tooltip"')
    end

    it "includes formatted currency values in circle data attributes" do
      get portfolio_path

      expect(response.body).to include('data-value="$')
    end
  end
end
