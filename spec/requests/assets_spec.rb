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

    it "shows open positions under Holdings" do
      asset = mxn_asset(symbol: "WALMEX", name: "Walmart de México", current_price: 70)
      create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)

      get assets_path

      expect(response.body).to include("WALMEX")
      expect(response.body).to include("Walmart de México")
    end

    # D68 orders the watchlist by distance to your own threshold. A list ranked
    # on a number the screen never prints reads as no order at all.
    it "states the gap it ranks each row on" do
      asset = mxn_asset(symbol: "WALMEX", current_price: 100)
      create(:watchlist_item, user: user, asset: asset, entry_price: 90)
      create(:alert_rule, user: user, asset_symbol: "WALMEX", condition: "price_crosses_below",
                          threshold_value: 90, status: :active)

      get assets_path(tab: "watchlist")

      expect(response.body).to include(I18n.t("assets.index.falta", percent: "10.0%"))
    end

    it "keeps the since-you-followed reading for a row with no threshold" do
      asset = mxn_asset(symbol: "GAP", current_price: 110)
      create(:watchlist_item, user: user, asset: asset, entry_price: 100)

      get assets_path(tab: "watchlist")

      expect(response.body).to include(I18n.t("assets.index.sigues", percent: "+10.0%"))
      expect(response.body).not_to include(I18n.t("assets.index.falta", percent: "10.0%"))
    end

    it "prints the gaps in the order it sorted them" do
      near = mxn_asset(symbol: "NEAR", current_price: 100)
      far  = mxn_asset(symbol: "FAR", current_price: 100)
      create(:watchlist_item, user: user, asset: near)
      create(:watchlist_item, user: user, asset: far)
      create(:alert_rule, user: user, asset_symbol: "NEAR", condition: "price_crosses_below",
                          threshold_value: 96, status: :active)
      create(:alert_rule, user: user, asset_symbol: "FAR", condition: "price_crosses_below",
                          threshold_value: 80, status: :active)

      get assets_path(tab: "watchlist")

      expect(response.body.index("NEAR")).to be < response.body.index("FAR")
      expect(response.body.index(I18n.t("assets.index.falta", percent: "4.0%")))
        .to be < response.body.index(I18n.t("assets.index.falta", percent: "20.0%"))
    end

    it "shows the watchlist under Watchlist, not the portfolio" do
      held = mxn_asset(symbol: "HELD", current_price: 10)
      watched = mxn_asset(symbol: "WATCHED", current_price: 10)
      create(:position, portfolio: portfolio, asset: held, shares: 1, avg_cost: 10, status: :open)
      create(:watchlist_item, user: user, asset: watched, entry_price: 8)

      get assets_path(tab: "watchlist")

      expect(response.body).to include("WATCHED")
      expect(response.body).not_to include("HELD")
    end

    it "renders entry_price as the gain since you started following" do
      asset = mxn_asset(symbol: "NVDA", current_price: 120)
      create(:watchlist_item, user: user, asset: asset, entry_price: 100)

      get assets_path(tab: "watchlist")

      expect(response.body).to include("sigues +20.0%")
    end

    it "falls back to Holdings for an unknown tab" do
      get assets_path(tab: "../../etc/passwd")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(I18n.t("assets.index.vacio_cartera_titulo"))
    end

    # The empty portfolio is exactly when the importer has to be visible, and
    # the foot-of-list row is what keeps it reachable once holdings exist.
    it "offers the importer whether or not the portfolio has holdings" do
      get assets_path

      expect(response.body.scan(%r{href="#{new_trade_import_path}"}).size).to eq(2)

      create(:position, portfolio: portfolio, asset: mxn_asset(symbol: "AMXL", current_price: 15), shares: 1, avg_cost: 12, status: :open)
      get assets_path

      expect(response.body).to include(%(href="#{new_trade_import_path}"))
    end

    it "leads each holding with what it is worth, not with the day's move (D69)" do
      asset = with_day_change(mxn_asset(symbol: "WALMEX", current_price: 70), 1.5)
      create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)

      get assets_path

      expect(response.body).to match(%r{text-sm font-bold text-fg-default">\s*7,000\s*</p>})
      expect(response.body).to match(%r{text-xs text-positive">\s*\+1\.5%\s*</p>})
    end

    # ADR-021: one close is no day change. Rendering 0% would report the row
    # as flat, which is a different claim from having nothing to compare.
    it "draws a dash for a holding with no previous close" do
      asset = mxn_asset(symbol: "NUEVA", current_price: 10, change_percent_24h: 4.0)
      create(:asset_price_history, asset: asset, date: Date.current,
                                   open: 10, high: 10, low: 10, close: 10)
      create(:position, portfolio: portfolio, asset: asset, shares: 1, avg_cost: 10, status: :open)

      get assets_path

      expect(response.body).to match(%r{text-xs text-fg-subtle">\s*—\s*</p>})
      expect(response.body).not_to include("+4.0%")
      expect(response.body).not_to include("+0.0%")
    end

    it "orders the holdings by market value descending (D68)" do
      %w[SMALL BIG MID].zip([ 1, 100, 10 ]).each do |symbol, shares|
        create(:position, portfolio: portfolio, asset: mxn_asset(symbol: symbol, current_price: 10),
                          shares: shares, avg_cost: 1, status: :open)
      end

      get assets_path

      expect(response.body.scan(/\b(?:SMALL|BIG|MID)\b/).uniq).to eq(%w[BIG MID SMALL])
    end

    # X15: the sparkline used to read PriceSeries once per row.

    it "declares the currency once and drops the symbol from the rows" do
      asset = mxn_asset(symbol: "AMXL", current_price: 15)
      create(:position, portfolio: portfolio, asset: asset, shares: 1_000, avg_cost: 12, status: :open)

      get assets_path

      expect(response.body).to include("VALOR DE MERCADO · MXN")
      expect(response.body).to match(%r{text-sm font-bold text-fg-default">\s*15,000\s*</p>})
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
