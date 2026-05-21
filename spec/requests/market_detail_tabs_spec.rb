require "rails_helper"

# Tab content rendering (S10 #93). Tabs are now adaptive: surfaced only
# when underlying data exists. We assert metric copy is in es-MX and
# financial-statement labels come through the lazy frame.
RSpec.describe "Market Asset Detail Tabs", type: :request do
  let!(:user) { create(:user, email: "tabs@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 227.44, country: "US") }

  before { login_as(user) }

  describe "Valoración tab" do
    it "renders valuation metrics when fundamentals exist" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
        metrics: { "pe_ratio" => "31.25", "ev_ebitda" => "22.10", "market_cap" => "3230000000000" })

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("P/E Ratio")
      expect(response.body).to include("EV/EBITDA")
      expect(response.body).to include("Market Cap")
    end

    it "renders profitability-style metrics on the Resumen tab via the summary metric set" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
        metrics: { "return_on_equity" => "1.57", "profit_margin" => "0.246" })

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Return on Equity")
      expect(response.body).to include("Net Margin")
    end

    it "renders the es-MX empty state when no fundamentals" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sin datos fundamentales")
    end
  end

  describe "Estados financieros (lazy-loaded)" do
    it "renders financial statement data via the lazy tab endpoint" do
      create(:financial_statement, asset: asset,
        statement_type: :income_statement, period_type: :annual,
        fiscal_date_ending: Date.new(2024, 9, 28), fiscal_year: 2024,
        data: { "totalRevenue" => "394328000000", "netIncome" => "97000000000" })

      get market_asset_statements_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Estado de resultados")
      expect(response.body).to include("Balance general")
      expect(response.body).to include("Flujo de efectivo")
      expect(response.body).to include("FY2024")
    end

    it "shows an es-MX empty state when no statements exist" do
      get market_asset_statements_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sin estados financieros")
    end
  end

  describe "navigation links" do
    it "market listings link to the asset detail page" do
      get market_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(market_asset_path(asset.symbol))
    end
  end
end
