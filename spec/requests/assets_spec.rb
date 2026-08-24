require "rails_helper"

RSpec.describe "Activos", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current, preferred_currency: "MXN") }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before { login_as(user) }

  def mxn_asset(**attrs)
    create(:asset, :stock, currency: "MXN", **attrs)
  end

  describe "GET /assets" do
    it "does not collide with Propshaft, which owns the same prefix" do
      get "/assets"
      expect(response).to have_http_status(:ok)

      get "/assets/#{Rails.application.assets.load_path.find("application.js")&.digested_path || "application.js"}"
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/javascript")
    end

    it "shows open positions under Cartera" do
      asset = mxn_asset(symbol: "WALMEX", name: "Walmart de México", current_price: 70)
      create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)

      get assets_path

      expect(response.body).to include("WALMEX")
      expect(response.body).to include("Walmart de México")
    end

    it "shows the watchlist under Sigo, not the portfolio" do
      held = mxn_asset(symbol: "HELD", current_price: 10)
      watched = mxn_asset(symbol: "WATCHED", current_price: 10)
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 10, status: :open)
      create(:watchlist_item, user: user, asset: watched, entry_price: 8)

      get assets_path(tab: "sigo")

      expect(response.body).to include("WATCHED")
      expect(response.body).not_to include("HELD")
    end

    it "renders entry_price as the gain since you started following" do
      asset = mxn_asset(symbol: "NVDA", current_price: 120)
      create(:watchlist_item, user: user, asset: asset, entry_price: 100)

      get assets_path(tab: "sigo")

      expect(response.body).to include("sigues +20.0%")
    end

    it "falls back to Cartera for an unknown tab" do
      get assets_path(tab: "../../etc/passwd")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("assets.index.vacio_cartera_titulo"))
    end

    it "declares the currency once and drops the symbol from the rows" do
      asset = mxn_asset(symbol: "AMXL", current_price: 15)
      create(:position, portfolio: portfolio, asset: asset, shares: 1_000, avg_cost: 12, status: :open)

      get assets_path

      expect(response.body).to include("VALOR DE MERCADO · MXN")
      expect(response.body).to include(">\n      15,000\n    <")
    end
  end

  describe "when the FX rate for a held currency is missing" do
    let!(:usd_position) do
      asset = create(:asset, :stock, symbol: "AAPL", currency: "USD", current_price: 100)
      create(:position, portfolio: portfolio, asset: asset, shares: 5, avg_cost: 80, status: :open)
    end

    # /dashboard and /portfolio raise a 500 in exactly this setup. Consolidation
    # is what becomes impossible, not the list — so this screen degrades.
    it "renders the holdings instead of failing" do
      get assets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AAPL")
    end

    it "says it cannot consolidate rather than inventing a rate" do
      get assets_path

      expect(response.body).to include(I18n.t("comun.sin_tc_titulo"))
      expect(response.body).not_to include("VALOR DE MERCADO · MXN")
    end

    it "keeps the ISO prefix on the value it could not convert" do
      get assets_path

      expect(response.body).to include("USD 500")
    end
  end
end
