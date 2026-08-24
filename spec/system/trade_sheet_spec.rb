require "rails_helper"

# D11. What a headless browser can prove: the route is real, the frame loads,
# the dialog opens and closes, the total recalculates, and the FX field fills
# with the rate for the date entered. What it cannot prove is the reason the
# sticky footer exists — an iOS keyboard covering a bottom-anchored sheet does
# not reproduce here. That acceptance is the `Con teclado` artboard on a phone.
RSpec.describe "Registrar movimiento", type: :system, js: true do
  let!(:user) { create(:user, email: "sheet@test.com", password: "password123", onboarded_at: Time.current, preferred_currency: "MXN") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:asset) { create(:asset, :stock, symbol: "AAPL", name: "Apple", currency: "USD", current_price: 180) }

  before do
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 12), rate: 17.0, source: "banxico_fix")
    visit login_path
    fill_in "Correo electrónico", with: "sheet@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    visit assets_path
  end

  it "opens the sheet without leaving Activos" do
    click_link "Registrar movimiento"

    expect(page).to have_css("dialog[open]")
    expect(page).to have_field("trade[asset_symbol]")
    expect(page).to have_current_path(new_trade_path)
  end

  it "closes on the X and forgets what was typed" do
    click_link "Registrar movimiento"
    fill_in "trade[asset_symbol]", with: "AAPL"
    find("button[aria-label='Cerrar']").click

    expect(page).to have_no_css("dialog[open]")

    click_link "Registrar movimiento"
    expect(page).to have_field("trade[asset_symbol]", with: "")
  end

  it "keeps the total in view while the fields are filled" do
    click_link "Registrar movimiento"
    fill_in "trade[shares]", with: "10"
    fill_in "trade[price_per_share]", with: "150"

    expect(page).to have_css("[data-trade-sheet-target='total']", text: "MXN 1,500.00")
  end

  it "fills the FX rate with the fix of the date entered, not of today" do
    click_link "Registrar movimiento"
    select "USD", from: "trade[currency]"
    fill_in "trade[executed_at]", with: "2026-05-12"

    expect(page).to have_field("trade[fx_rate_at_execution]", with: "17")
  end

  it "hides the FX field when there is nothing to convert" do
    click_link "Registrar movimiento"
    select "MXN", from: "trade[currency]"

    expect(page).to have_no_css("[data-trade-sheet-target='fxCard']", visible: :visible)
  end
end
