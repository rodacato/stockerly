require "rails_helper"

RSpec.describe "Market Asset Detail", type: :request do
  let!(:user) { create(:user, email: "detail@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 227.44, sector: "Technology", exchange: "NASDAQ", country: "US") }

  before { login_as(user) }

  describe "GET /market/:symbol" do
    it "renders the asset detail page" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Apple Inc.")
      expect(response.body).to include("AAPL")
    end

    it "shows fundamental metrics when data exists" do
      create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
        metrics: { "eps" => "6.07", "beta" => "1.24", "pe_ratio" => "31.25" })

      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("P/E Ratio")
      expect(response.body).to include("Beta")
    end

    it "shows empty state when no fundamentals" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No fundamental data available")
    end

    it "redirects to market index when asset not found" do
      get market_asset_path("INVALID")

      expect(response).to redirect_to(market_path)
    end

    it "shows watchlist status for watched assets" do
      create(:watchlist_item, user: user, asset: asset)
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Watching")
    end

    it "shows add to watchlist button for unwatched assets" do
      get market_asset_path(asset.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Add to Watchlist")
    end

    it "renders tab navigation" do
      get market_asset_path(asset.symbol)

      expect(response.body).to include("Summary")
      expect(response.body).to include("Valuation")
      expect(response.body).to include("Profitability")
      expect(response.body).to include("Health")
      expect(response.body).to include("Growth")
      expect(response.body).to include("Dividends")
      expect(response.body).to include("Statements")
    end

    it "shows GAAP label based on country" do
      create(:asset_fundamental, asset: asset)
      get market_asset_path(asset.symbol)

      expect(response.body).to include("US GAAP")
    end

    it "renders fixed income detail for CETES assets" do
      cetes = create(:asset, :fixed_income, symbol: "CETES_28D", name: "CETES 28 Days",
                     yield_rate: 11.15, face_value: 10.0, maturity_date: 20.days.from_now.to_date)

      get market_asset_path(cetes.symbol)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Yield Information")
      expect(response.body).to include("Fixed Income")
      expect(response.body).to include("Banxico")
    end
  end
end
