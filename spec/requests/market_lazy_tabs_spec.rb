require "rails_helper"

# Lazy tab endpoints (S10 #93). After the adaptive-tab redesign, only
# Estados financieros is surfaced as a lazy turbo_frame on the show
# page; Earnings is reachable via its endpoint (used elsewhere) but not
# embedded on /market/:symbol.
RSpec.describe "Market lazy-loaded tabs", type: :request do
  let!(:user) { create(:user, email: "lazytabs@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "MSFT", name: "Microsoft Corp.", current_price: 430.0, sector: "Technology", exchange: "NASDAQ", country: "US") }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    it "renders the lazy Turbo Frame placeholder for the Estados financieros tab when data exists" do
      create(:financial_statement, asset: asset,
        statement_type: :income_statement, period_type: :annual,
        fiscal_date_ending: Date.new(2024, 6, 30), fiscal_year: 2024,
        data: { "totalRevenue" => "245000000000" })

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="asset_statements_tab"')
      expect(response.body).to include('loading="lazy"')
    end

    it "does NOT embed an Earnings turbo frame on the show page" do
      get market_asset_path(asset.symbol)

      expect(response.body).not_to include('id="asset_earnings_tab"')
    end
  end

  describe "GET /market/:symbol/earnings_tab" do
    it "renders earnings content (es-MX) inside a Turbo Frame" do
      create(:earnings_event, asset: asset, report_date: 10.days.ago, estimated_eps: 2.50, actual_eps: 2.75)

      get market_asset_earnings_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("asset_earnings_tab")
      expect(response.body).to include("Fecha del reporte")
      expect(response.body).to include("2.75")
    end

    it "renders the es-MX empty state when no earnings data" do
      get market_asset_earnings_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sin reportes disponibles")
    end
  end

  describe "GET /market/:symbol/statements_tab" do
    it "renders statements content inside a Turbo Frame" do
      get market_asset_statements_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("asset_statements_tab")
    end

    it "shows an es-MX empty state when no statements exist" do
      get market_asset_statements_tab_path(asset.symbol)

      expect(response.body).to include("Sin estados financieros")
    end
  end
end
