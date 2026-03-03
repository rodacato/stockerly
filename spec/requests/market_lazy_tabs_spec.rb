require "rails_helper"

RSpec.describe "Market lazy-loaded tabs", type: :request do
  let!(:user) { create(:user, email: "lazytabs@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "MSFT", name: "Microsoft Corp.", current_price: 430.0, sector: "Technology", exchange: "NASDAQ", country: "US") }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    it "renders lazy Turbo Frame placeholders for Earnings and Statements tabs" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="asset_earnings_tab"')
      expect(response.body).to include('loading="lazy"')
      expect(response.body).to include('id="asset_statements_tab"')
    end

    it "shows skeleton loaders inside lazy frames" do
      get market_asset_path(asset.symbol)

      expect(response.body).to include("animate-pulse")
      expect(response.body).to include("skeleton-shimmer")
    end
  end

  describe "GET /market/:symbol/earnings_tab" do
    it "renders earnings content inside a Turbo Frame" do
      create(:earnings_event, asset: asset, report_date: 10.days.ago, estimated_eps: 2.50, actual_eps: 2.75)

      get market_asset_earnings_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("asset_earnings_tab")
      expect(response.body).to include("Report Date")
      expect(response.body).to include("$2.75")
    end

    it "renders empty state when no earnings data" do
      get market_asset_earnings_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No earnings data available")
    end
  end

  describe "GET /market/:symbol/statements_tab" do
    it "renders statements content inside a Turbo Frame" do
      get market_asset_statements_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("asset_statements_tab")
    end

    it "shows empty state when no statements exist" do
      get market_asset_statements_tab_path(asset.symbol)

      expect(response.body).to include("No financial statements")
    end
  end
end
