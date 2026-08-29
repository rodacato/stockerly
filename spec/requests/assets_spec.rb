require "rails_helper"

RSpec.describe "Activos", type: :request do
  let(:user) { create(:user, onboarded_at: Time.current, preferred_currency: "MXN") }
  let(:portfolio) { user.portfolio || create(:portfolio, user: user) }

  before { login_as(user) }

  def price_history_queries
    hits = []
    sub = ActiveSupport::Notifications.subscribe("sql.active_record") do |_n, _s, _f, _id, payload|
      sql = payload[:sql]
      hits << sql if sql.include?("asset_price_histories")
    end
    yield
    hits.size
  ensure
    ActiveSupport::Notifications.unsubscribe(sub) if sub
  end

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
      asset = mxn_asset(symbol: "WALMEX", current_price: 70, change_percent_24h: 1.5)
      create(:position, portfolio: portfolio, asset: asset, shares: 100, avg_cost: 60, status: :open)

      get assets_path

      expect(response.body).to match(%r{text-sm font-bold text-fg-default">\s*7,000\s*</p>})
      expect(response.body).to match(%r{text-xs text-positive">\s*\+1\.5%\s*</p>})
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
    it "draws every sparkline from a single price-history query" do
      3.times do |i|
        asset = mxn_asset(symbol: "SYM#{i}", current_price: 10)
        create(:position, portfolio: portfolio, asset: asset, shares: 1, avg_cost: 1, status: :open)
        2.times { |d| create(:asset_price_history, asset: asset, date: d.days.ago.to_date, close: 10 + d) }
      end

      expect(price_history_queries { get assets_path }).to eq(1)
    end

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
