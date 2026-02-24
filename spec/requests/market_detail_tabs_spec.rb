require "rails_helper"

RSpec.describe "Market Asset Detail Tabs", type: :request do
  let!(:user) { create(:user, email: "tabs@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 227.44, country: "US") }

  before { login_as(user) }

  describe "category tabs" do
    it "renders valuation metrics when fundamentals exist" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
        metrics: { "pe_ratio" => "31.25", "ev_ebitda" => "22.10", "market_cap" => "3230000000000" })

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("P/E Ratio")
      expect(response.body).to include("EV/EBITDA")
      expect(response.body).to include("Market Cap")
    end

    it "renders profitability metrics" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
        metrics: { "return_on_equity" => "1.57", "profit_margin" => "0.246" })

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Return on Equity")
      expect(response.body).to include("Net Margin")
    end

    it "renders empty state for all tabs when no fundamentals" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No fundamental data available")
      expect(response.body).to include("No data available")
    end
  end

  describe "statements tab" do
    it "renders financial statement data when available" do
      create(:financial_statement, asset: asset,
        statement_type: :income_statement, period_type: :annual,
        fiscal_date_ending: Date.new(2024, 9, 28), fiscal_year: 2024,
        data: { "totalRevenue" => "394328000000", "netIncome" => "97000000000" })

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Income Statement")
      expect(response.body).to include("Balance Sheet")
      expect(response.body).to include("Cash Flow")
      expect(response.body).to include("FY2024")
    end

    it "shows empty state when no statements exist" do
      create(:asset_fundamental, asset: asset)

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No financial statements")
    end
  end

  describe "navigation links" do
    it "market listings link to asset detail page" do
      get market_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(market_asset_path(asset.symbol))
    end
  end
end
