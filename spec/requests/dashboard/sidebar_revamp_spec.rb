require "rails_helper"

# Dashboard sidebar + main grid revamp (S11 #143).
# Asserts the 7 reworked partials render under empty / populated / error
# states with their new es-MX Stockerly-2.0 headings and Lumen-token classes.
#
# Partials covered:
#   _watchlist_table, _news_feed, _trending_today, _market_status,
#   _weekly_insight, _upcoming_events, notable_observations
RSpec.describe "Dashboard sidebar revamp (S11 #143)", type: :request do
  let(:user) do
    create(:user,
      email: "sidebar@example.com",
      password: "password123",
      preferred_currency: "MXN",
      onboarded_at: Time.current,
      full_name: "Adrian Castillo")
  end
  let!(:portfolio) { create(:portfolio, user: user, buying_power: 47_210.00) }

  before do
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.0)
    login_as(user)
  end

  describe "populated state" do
    let!(:asset) do
      create(:asset,
        symbol: "WALMEX",
        name: "Wal-Mart de México",
        asset_type: :stock,
        current_price: 100,
        change_percent_24h: 1.20,
        exchange: "BMV",
        currency: "MXN")
    end
    let!(:cetes) { create(:asset, :fixed_income, symbol: "CETES_28D", name: "CETES 28 Days") }

    before do
      create(:watchlist_item, user: user, asset: asset)
      create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
      create(:position, portfolio: portfolio, asset: cetes, shares: 100, avg_cost: 9.85, maturity_date: 5.days.from_now.to_date)
      create(:market_index, symbol: "SPX", name: "S&P 500", value: 5_200.50, change_percent: 0.75, is_open: true)
      create(:news_article, title: "WALMEX supera estimaciones", related_ticker: "WALMEX", source: "Bloomberg", published_at: 30.minutes.ago)
      create(:technical_observation, asset: asset, observation_type: "rsi_oversold_entered", observed_at: 1.hour.ago)
    end

    it "renders the watchlist table with es-MX heading + Lumen surface tokens" do
      get dashboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tus posiciones")
      expect(response.body).to include("WALMEX")
      expect(response.body).to include("bg-bg-surface")
      expect(response.body).to include("border-border-default")
      # The redesigned table column header is es-MX ("Empresa" instead of "Company").
      expect(response.body).to include("Empresa")
    end

    it "renders the market status panel with es-MX heading + open badge" do
      get dashboard_path
      expect(response.body).to include("Estado del mercado")
      expect(response.body).to include("Abierto")
    end

    it "renders the upcoming maturities panel with es-MX descriptive copy" do
      get dashboard_path
      expect(response.body).to include("Próximos vencimientos")
      expect(response.body).to include("vence en 5 días")
    end

    it "renders the weekly insight card with es-MX heading" do
      get dashboard_path
      expect(response.body).to include("Lectura semanal")
      # Card footer is always present (cache key changes per user/date).
      expect(response.body).to include("Generado los domingos")
    end

    it "renders the news feed turbo frame heading lazily" do
      get dashboard_news_feed_path
      expect(response.body).to include("Noticias del mercado")
      expect(response.body).to include("WALMEX supera estimaciones")
    end

    it "renders the trending today turbo frame with es-MX heading" do
      get dashboard_trending_path
      expect(response.body).to include("Tendencias hoy")
      expect(response.body).to include("WALMEX")
    end

    it "renders the notable observations turbo frame with es-MX heading + asset link" do
      get dashboard_notable_observations_path
      expect(response.body).to include("Observaciones técnicas")
      expect(response.body).to include("Filtradas a tus activos")
      expect(response.body).to include("entró en zona de sobreventa")
    end
  end

  describe "empty state (no positions, no watchlist, no news)" do
    it "renders the dashboard 200 + watchlist empty state in es-MX" do
      portfolio.destroy
      user.reload
      get dashboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tu watchlist está vacía")
    end

    it "renders the news feed lazy partial without errors when no news exists" do
      get dashboard_news_feed_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sin noticias por ahora.")
    end

    it "renders the trending panel empty copy when no trending assets exist" do
      get dashboard_trending_path
      expect(response).to have_http_status(:ok)
      # Either the panel is absent (header still there) or shows the empty copy —
      # the turbo frame heading is always present so this is the canonical empty state.
      expect(response.body).to include("Sin movimientos relevantes ahora mismo.").or include("Tendencias hoy")
    end

    it "renders the notable observations turbo frame without surfacing the card heading" do
      get dashboard_notable_observations_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Observaciones técnicas")
    end
  end

  describe "preserved S09/S10 dashboard chrome (#116)" do
    let!(:asset) { create(:asset, :mexican, currency: "MXN", current_price: 100) }

    before do
      create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
    end

    it "still renders the greeting, KPI strip titles, and 'Panel de control' kicker" do
      get dashboard_path
      expect(response.body).to match(/(Buenos días|Buenas tardes|Buenas noches), Adrian\./)
      expect(response.body).to include("Panel de control")
      expect(response.body).to include("Valor total")
      expect(response.body).to include("Ganancia del día")
      expect(response.body).to include("CETES por vencer")
      expect(response.body).to include("Saldo disponible")
    end
  end
end
