require "rails_helper"

# /trades chrome — filter strip + footer totals + inline delete-confirm
# + empty-state CTA, per S11 #145. Driven by rack_test (no JS).
RSpec.describe "Trades filters, footer and empty state", type: :system do
  before { driven_by :rack_test }

  let!(:user) do
    create(:user,
           email: "trades_chrome@test.com",
           password: "password123",
           onboarded_at: Time.current,
           email_verified_at: Time.current)
  end
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:mxn_asset) { create(:asset, :mexican, symbol: "WALMEX", currency: "MXN", current_price: 64.0) }
  let!(:usd_asset) { create(:asset, symbol: "NVDA", currency: "USD", current_price: 580.0) }
  let!(:mxn_position) do
    create(:position, portfolio: portfolio, asset: mxn_asset,
           shares: 100, avg_cost: 60.0, status: :open)
  end

  before do
    # FX rates are required when the dashboard renders mixed-currency
    # positions on the way through the login redirect.
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.0)
    create(:fx_rate, base_currency: "MXN", quote_currency: "USD", rate: 1.0 / 17.0)

    visit login_path
    fill_in "Correo electrónico", with: "trades_chrome@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  context "when the portfolio has no trades" do
    it "shows the empty state with CTA back to portfolio" do
      visit trades_path

      expect(page).to have_content("Aún no hay movimientos registrados.")
      expect(page).to have_link("Registra tu primer trade", href: portfolio_path)
    end

    it "hides the filter strip when there are no trades" do
      visit trades_path

      expect(page).not_to have_content("Filtros")
    end
  end

  context "with multiple trades across currencies and years" do
    let!(:mxn_buy) do
      create(:trade, portfolio: portfolio, asset: mxn_asset, position: mxn_position,
             side: :buy, shares: 100, price_per_share: 60.0, total_amount: 6000.0,
             currency: "MXN", executed_at: 5.days.ago)
    end
    let!(:usd_buy) do
      create(:trade, portfolio: portfolio, asset: usd_asset,
             side: :buy, shares: 5, price_per_share: 580.0, total_amount: 2900.0,
             currency: "USD", executed_at: 3.days.ago)
    end
    let!(:mxn_sell) do
      create(:trade, portfolio: portfolio, asset: mxn_asset, position: mxn_position,
             side: :sell, shares: 20, price_per_share: 65.0, total_amount: 1300.0,
             currency: "MXN", executed_at: 1.day.ago)
    end

    it "renders the filter strip with Tipo, Mercado and Año chips" do
      visit trades_path

      expect(page).to have_content("Filtros")
      expect(page).to have_content("Tipo")
      expect(page).to have_content("Mercado")
      expect(page).to have_content("Año")
      expect(page).to have_link("Compras")
      expect(page).to have_link("Ventas")
      expect(page).to have_link("MXN")
      expect(page).to have_link("USD")
    end

    it "filters trades by tipo=compras (only buys remain)" do
      visit trades_path(tipo: "compras")

      expect(page).to have_css("td", text: "WALMEX")
      expect(page).to have_css("td", text: "NVDA")
      # No "Venta" rendering inside table body (the chip is buy only)
      within("#trade_history") do
        expect(page).not_to have_content("Venta")
      end
    end

    it "filters trades by mercado=usd (only USD rows remain)" do
      visit trades_path(mercado: "usd")

      within("#trade_history") do
        expect(page).to have_content("NVDA")
        expect(page).not_to have_content("WALMEX")
      end
    end

    it "renders the footer with per-currency totals and trade count" do
      visit trades_path

      expect(page).to have_content("En pantalla · 3 movimientos")
      # Total invertido MXN = 6000.00; USD = 2900.00 (from the two compras)
      expect(page).to have_content(/Invertido\s+MXN\s+6,000\.00/)
      expect(page).to have_content(/Invertido\s+USD\s+2,900\.00/)
      # G/P realizada MXN = (1300 - 20*60 - 0) = 100.00
      expect(page).to have_content("G/P realizada")
      expect(page).to have_content(/MXN\s+100\.00/)
    end

    it "shows the filter empty state when filters match nothing" do
      visit trades_path(mercado: "usd", tipo: "ventas")

      expect(page).to have_content("Sin coincidencias con tus filtros.")
      expect(page).to have_link("Limpiar filtros")
    end

    it "shows the 'Mostrando X de Y' chip honestly" do
      visit trades_path(mercado: "usd")

      expect(page).to have_content("Mostrando")
      # 1 of 3 (only NVDA matches USD filter)
      expect(page).to have_content(/Mostrando\s*1\s*de\s*3/)
    end

    it "exposes the inline delete-confirm row via confirm_destroy" do
      get_url = confirm_destroy_trade_path(mxn_sell, format: :turbo_stream)
      visit get_url

      expect(page.body).to include("¿Eliminar este movimiento permanentemente?")
      expect(page.body).to include("Sí, eliminar")
    end
  end
end
