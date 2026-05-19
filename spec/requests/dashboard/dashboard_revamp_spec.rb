require "rails_helper"

# Dashboard revamp (S09 #90) — asserts es-MX surface + KPI structure.
# Keep this file focused on the revamp; behavioral specs for individual
# turbo-frame sections live in sibling files (compact_news_feed_spec,
# market_indices_spec, lazy_sections_spec, fear_greed_*_spec).
RSpec.describe "Dashboard revamp (S09 #90)", type: :request do
  let(:user) { create(:user, preferred_currency: "MXN", onboarded_at: Time.current, full_name: "Adrian Castillo") }

  before do
    login_as(user)
    # Avoid hitting handlers that need real FX rates we don't seed here
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.0)
  end

  describe "GET /dashboard" do
    let!(:portfolio) { create(:portfolio, user: user, buying_power: 47_210.00) }

    before do
      asset = create(:asset, :mexican, currency: "MXN", current_price: 100)
      create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
      get dashboard_path
    end

    it "responds 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders an es-MX hour-aware greeting with the user's first name" do
      expect(response.body).to match(/(Buenos días|Buenas tardes|Buenas noches), Adrian\./)
    end

    it "renders the four S09 KPI titles in es-MX" do
      expect(response.body).to include("Valor total")
      expect(response.body).to include("Ganancia del día")
      expect(response.body).to include("CETES por vencer")
      expect(response.body).to include("Saldo disponible")
    end

    it "formats currency with the MXN ISO prefix (not the generic $ symbol)" do
      expect(response.body).to match(/MXN\s+[\d,]+\.\d{2}/)
    end

    it "does NOT contain the previous English copy" do
      expect(response.body).not_to include("Welcome back")
      expect(response.body).not_to include("Total Balance")
      expect(response.body).not_to include("Day Gain/Loss")
      expect(response.body).not_to include("Buying Power")
      expect(response.body).not_to include("Watchlist Sentiment")
    end

    it "renders the 'Panel de control' kicker" do
      expect(response.body).to include("Panel de control")
    end
  end

  describe "GET /dashboard with empty state" do
    it "renders the es-MX empty state when watchlist + portfolio are empty" do
      get dashboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Tu watchlist está vacía")
      expect(response.body).to include("Explorar mercado")
    end
  end
end
