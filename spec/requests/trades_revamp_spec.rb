require "rails_helper"

# Trades (Movimientos) revamp (S09 #98) — asserts es-MX surface +
# currency-aware columns + summary aggregation. Behavioral specs for
# create/update/destroy live in spec/requests/trades_spec.rb.
RSpec.describe "Trades revamp (S09 #98)", type: :request do
  let(:user) { create(:user, email: "t98@example.com", preferred_currency: "MXN", password: "password123") }
  let!(:portfolio) { create(:portfolio, user: user, buying_power: 50_000.0) }
  let(:mxn_asset) { create(:asset, :mexican, symbol: "ICA", currency: "MXN", current_price: 50.0) }
  let(:usd_asset) { create(:asset, symbol: "AAPL", currency: "USD", current_price: 189.0) }

  before do
    login_as(user)
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.0)
  end

  describe "GET /trades — header + empty state" do
    it "renders the es-MX header" do
      get trades_path
      expect(response.body).to include("Movimientos")
      expect(response.body).to include("Historial auditable")
      expect(response.body).to include("Volver al portafolio")
    end

    it "renders the es-MX empty state when no trades exist" do
      get trades_path
      expect(response.body).to include("Aún no hay movimientos")
    end

    it "does NOT contain the previous English copy" do
      get trades_path
      expect(response.body).not_to include("Trade History")
      expect(response.body).not_to include("Back to Portfolio")
      expect(response.body).not_to include("No trades yet")
    end
  end

  describe "GET /trades with mixed-currency trades" do
    before do
      # MXN trade (compra)
      create(:trade, portfolio: portfolio, asset: mxn_asset, side: "buy", shares: 100, price_per_share: 48.0, total_amount: 4800.0, currency: "MXN", executed_at: 1.day.ago)
      # USD trade (compra)
      create(:trade, portfolio: portfolio, asset: usd_asset, side: "buy", shares: 10, price_per_share: 150.0, total_amount: 1500.0, currency: "USD", executed_at: 2.days.ago)
      # MXN trade (venta)
      create(:trade, portfolio: portfolio, asset: mxn_asset, side: "sell", shares: 20, price_per_share: 52.0, total_amount: 1040.0, currency: "MXN", executed_at: 3.days.ago)
      get trades_path
    end

    it "renders the summary cards with per-currency totals" do
      expect(response.body).to include("Total compras")
      expect(response.body).to include("Total ventas")
      expect(response.body).to include("Comisiones")
      # MXN compras = 4800, USD compras = 1500
      expect(response.body).to match(/MXN\s+4,800\.00/)
      expect(response.body).to match(/USD\s+1,500\.00/)
      # MXN ventas = 1040
      expect(response.body).to match(/MXN\s+1,040\.00/)
    end

    it "renders es-MX table headers" do
      expect(response.body).to include("Fecha")
      expect(response.body).to include("Activo")
      expect(response.body).to include("Operación")
      expect(response.body).to include("Títulos")
      expect(response.body).to include("Precio")
      expect(response.body).to include("Total")
      expect(response.body).to include("Comisión")
      expect(response.body).to include("Acciones")
    end

    it "renders trade rows with the trade's currency prefix" do
      # Each row's total is formatted with the trade.currency, not a generic $
      expect(response.body).to match(/MXN\s+/)
      expect(response.body).to match(/USD\s+/)
    end

    it "uses 'Compra' / 'Venta' side chips instead of 'buy' / 'sell'" do
      expect(response.body).to include("Compra")
      expect(response.body).to include("Venta")
      expect(response.body).not_to match(/>buy</)
      expect(response.body).not_to match(/>sell</)
    end
  end

  describe "GET /trades/:id/edit (turbo_stream)" do
    let!(:trade) { create(:trade, portfolio: portfolio, asset: usd_asset, executed_at: 1.day.ago) }

    it "renders the edit row with es-MX buttons" do
      get edit_trade_path(trade), as: :turbo_stream
      expect(response.body).to include("Guardar")
      expect(response.body).to include("Cancelar")
    end
  end
end
