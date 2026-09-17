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
      expect(response.body).to include(I18n.t("market.metricas.pe_ratio.nombre"))
      expect(response.body).to include(I18n.t("market.metricas.ev_ebitda.nombre"))
      expect(response.body).to include(I18n.t("market.metricas.market_cap.nombre"))
    end

    it "renders profitability-style metrics on the Resumen tab via the summary metric set" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
        metrics: { "return_on_equity" => "1.57", "profit_margin" => "0.246" })

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("market.metricas.roe.nombre"))
      expect(response.body).to include(I18n.t("market.metricas.net_margin.nombre"))
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
        data: { "total_revenue" => "394328000000", "net_income" => "97000000000" })

      get market_asset_statements_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Estado de resultados")
      expect(response.body).to include("Balance general")
      expect(response.body).to include("Flujo de efectivo")
      expect(response.body).to include("FY2024")
    end

    # D124: the table read camelCase keys from rows stored in snake_case, so
    # every cell but EBITDA and inventory was an em dash.
    it "renders the values under the keys the sync stores" do
      create(:financial_statement, asset: asset, data: { "total_revenue" => "391035000000", "gross_profit" => "180683000000" })
      create(:financial_statement, :cash_flow, asset: asset, data: { "repurchase_of_capital_stock" => "-94949000000" })

      get market_asset_statements_tab_path(asset.symbol)

      expect(response.body).to include("USD 391.0B", "USD 180.7B", "46.2%", "USD -94.9B")
    end

    # D123: the label named Alpha Vantage while Yahoo wrote every statement.
    it "names the providers of the statements on file" do
      create(:financial_statement, asset: asset, source: "yfinance")

      get market_asset_statements_tab_path(asset.symbol)

      expect(response.body).to include("Fuente: Yahoo Finance ·")
      expect(response.body).not_to include("Alpha Vantage")
    end

    it "names both when older periods came from Alpha Vantage" do
      create(:financial_statement, asset: asset, source: "yfinance")
      create(:financial_statement, asset: asset, source: "alpha_vantage", fiscal_date_ending: Date.new(2019, 9, 28), fiscal_year: 2019)

      get market_asset_statements_tab_path(asset.symbol)

      expect(response.body).to include("Fuente: Yahoo Finance y Alpha Vantage ·")
    end

    it "shows an es-MX empty state when no statements exist" do
      get market_asset_statements_tab_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sin estados financieros")
    end
  end
end
