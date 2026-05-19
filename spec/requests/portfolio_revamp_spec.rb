require "rails_helper"

# Portfolio revamp (S09 #91) — asserts es-MX surface + MXN/USD currency prefix
# in positions table. Sibling specs (portfolio_spec, portfolio_empty_state_spec,
# portfolio_allocation_spec, chart_tooltips_spec) cover layout-specific behavior.
RSpec.describe "Portfolio revamp (S09 #91)", type: :request do
  let(:user) { create(:user, email: "p91@example.com", preferred_currency: "MXN", password: "password123") }
  let!(:portfolio) { create(:portfolio, user: user, buying_power: 10_000.0) }

  before do
    login_as(user)
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.0)
  end

  describe "GET /portfolio (header + KPI strip)" do
    before { get portfolio_path }

    it "responds 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the es-MX kicker and title" do
      expect(response.body).to include("Tu portafolio")
      expect(response.body).to include("Posiciones y movimientos")
    end

    it "renders the three S09 KPI titles in es-MX" do
      expect(response.body).to include("Valor total del portafolio")
      expect(response.body).to include("Ganancia no realizada")
      expect(response.body).to include("Saldo disponible")
    end

    it "formats currency with MXN ISO prefix" do
      expect(response.body).to match(/MXN\s+[\d,]+\.\d{2}/)
    end

    it "does NOT contain the previous English copy" do
      expect(response.body).not_to include("Investment Portfolio")
      expect(response.body).not_to include("Total Portfolio Value")
      expect(response.body).not_to include("Available Buying Power")
      expect(response.body).not_to include("Total Unrealized Gain")
    end
  end

  describe "GET /portfolio trade form (es-MX + currency selector)" do
    before { get portfolio_path }

    it "renders the trade form with es-MX labels" do
      expect(response.body).to include("Registrar movimiento")
      expect(response.body).to include("Nuevo movimiento")
      expect(response.body).to include("Ticker")
      expect(response.body).to include("Operación")
      expect(response.body).to include("Títulos")
      expect(response.body).to include("Precio por título")
    end

    it "includes a currency selector with MXN and USD options" do
      expect(response.body).to include('name="trade[currency]"')
      expect(response.body).to include("Auto (según activo)")
      expect(response.body).to include(">MXN<")
      expect(response.body).to include(">USD<")
    end

    it "includes an FX rate override field" do
      expect(response.body).to include('name="trade[fx_rate_at_execution]"')
      expect(response.body).to include("Auto (FIX Banxico)")
    end
  end

  describe "POST /trades with explicit currency" do
    let!(:asset) { create(:asset, :mexican, symbol: "ICA", currency: "MXN", current_price: 50.0) }

    it "accepts an MXN trade and renders the position with the MXN prefix in the positions table" do
      post trades_path, params: { trade: { asset_symbol: "ICA", side: "buy", shares: 100, price_per_share: 48.0, currency: "MXN" } }
      expect(response).to redirect_to(portfolio_path)
      follow_redirect!
      expect(response.body).to match(/MXN\s+[\d,]+\.\d{2}/)
    end

    it "accepts a USD trade and renders the position with the USD prefix in the positions table" do
      create(:asset, symbol: "AAPL", currency: "USD", current_price: 189.0)
      post trades_path, params: { trade: { asset_symbol: "AAPL", side: "buy", shares: 10, price_per_share: 150.0, currency: "USD" } }
      expect(response).to redirect_to(portfolio_path)
      follow_redirect!
      expect(response.body).to match(/USD\s+[\d,]+\.\d{2}/)
    end
  end

  describe "positions table tabs (es-MX)" do
    before { get portfolio_path }

    it "renders the four tab labels in es-MX" do
      expect(response.body).to include("Posiciones abiertas")
      expect(response.body).to include("Cerradas")
      expect(response.body).to include("Dividendos")
      expect(response.body).to include("Movimientos")
    end
  end

  describe "allocation sidebar (es-MX with type-first ordering)" do
    before { get portfolio_path }

    it "renders the section title in es-MX" do
      expect(response.body).to include("Distribución del portafolio")
    end

    it "orders 'Por tipo' before 'Por sector' (MX-investor priority)" do
      pos_by_type = response.body.index("Por tipo")
      pos_by_sector = response.body.index("Por sector")
      expect(pos_by_type).to be_present
      expect(pos_by_sector).to be_present
      expect(pos_by_type).to be < pos_by_sector
    end
  end
end
