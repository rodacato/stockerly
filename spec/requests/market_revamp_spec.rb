require "rails_helper"

# Market revamp (S09 #92) — asserts es-MX surface + MX-first index ordering
# + filter localization. Behavioral specs for ExploreAssets live in
# spec/contexts/market_data/use_cases/explore_assets_spec.rb; trend bar
# tests live in market_trend_breakdown_spec.rb.
RSpec.describe "Market revamp (S09 #92)", type: :request do
  let(:user) { create(:user, email: "m92@example.com", preferred_currency: "MXN", password: "password123") }

  before { login_as(user) }

  describe "GET /market — header + es-MX surface" do
    # Seed at least one asset so the listings table renders (the empty state
    # is exercised in a separate spec).
    before do
      create(:asset, symbol: "AAPL", currency: "USD", current_price: 150)
      get market_path
    end

    it "responds 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the es-MX kicker + title + subtitle" do
      expect(response.body).to include("Explorar")
      expect(response.body).to include("Mercados")
      expect(response.body).to include("Índices, tipo de cambio, acciones, CETES y cripto")
    end

    it "renders the localized listing section header" do
      expect(response.body).to include("Listado de mercado")
      expect(response.body).to include("activos encontrados")
    end

    it "renders localized table headers" do
      expect(response.body).to include("Activo / Ticker")
      expect(response.body).to include("Precio")
      expect(response.body).to include("Cambio (24h)")
      expect(response.body).to include("Fuerza de tendencia")
      expect(response.body).to include("Acción")
    end

    it "renders the empty-state and filter labels in es-MX" do
      expect(response.body).to include("Buscar activos")
      expect(response.body).to include("Tipo de activo")
      expect(response.body).to include("País")
      expect(response.body).to include("Aplicar")
    end

    it "does NOT contain the previous English copy" do
      expect(response.body).not_to include("Market Listings")
      expect(response.body).not_to include("Asset / Ticker")
      expect(response.body).not_to include("Search Assets")
      expect(response.body).not_to include("Asset Type")
      expect(response.body).not_to include("Trend Strength")
    end
  end

  describe "indices strip — MX-first ordering" do
    before do
      # Seed 5 major indices in random order to verify the explicit IPC-first sort
      create(:market_index, symbol: "SPX", name: "S&P 500", value: 5200)
      create(:market_index, symbol: "NDX", name: "NASDAQ 100", value: 18000)
      create(:market_index, symbol: "IPC", name: "IPC México", value: 55000)
      create(:market_index, symbol: "DJI", name: "Dow Jones", value: 38000)
      create(:market_index, symbol: "UKX", name: "FTSE 100", value: 8000)
      get market_path
    end

    it "renders IPC before the US indices (S09 #92 MX-first)" do
      pos_ipc = response.body.index("IPC México")
      pos_spx = response.body.index("S&amp;P 500") || response.body.index("S&P 500")
      pos_ndx = response.body.index("NASDAQ 100")
      expect(pos_ipc).to be_present
      expect(pos_spx).to be_present
      expect(pos_ndx).to be_present
      expect(pos_ipc).to be < pos_spx
      expect(pos_ipc).to be < pos_ndx
    end
  end

  describe "filter dropdown options (es-MX)" do
    before { get market_path }

    it "renders asset-type options in es-MX" do
      expect(response.body).to include(">Acciones<")
      expect(response.body).to include(">Cripto<")
      expect(response.body).to include(">Índices<")
      expect(response.body).to include(">CETES<")
    end

    it "renders country options in es-MX (México before Estados Unidos)" do
      pos_mx = response.body.index(">México<")
      pos_us = response.body.index(">Estados Unidos<")
      expect(pos_mx).to be_present
      expect(pos_us).to be_present
      expect(pos_mx).to be < pos_us
    end
  end

  describe "currency-aware price column" do
    before do
      create(:asset, :mexican, symbol: "ICA", currency: "MXN", current_price: 48.50)
      create(:asset, symbol: "AAPL", currency: "USD", current_price: 189.00)
      get market_path
    end

    it "renders each row with the asset's native currency prefix" do
      expect(response.body).to match(/MXN\s+48\.50/)
      expect(response.body).to match(/USD\s+189\.00/)
    end
  end
end
