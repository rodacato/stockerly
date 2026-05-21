require "rails_helper"

RSpec.describe "Alert management", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "alerts@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:preference) { create(:alert_preference, user: user) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "alerts@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "renders the Stockerly-2.0 header in es-MX with empty state" do
    visit alerts_path
    expect(page).to have_content("Tus alertas")
    expect(page).to have_content("Crear una alerta")
    expect(page).to have_content("Aún no tienes alertas configuradas")
  end

  it "exposes the MX-aware rule type chips" do
    visit alerts_path
    expect(page).to have_content("Precio cruza umbral")
    expect(page).to have_content("RSI sobrevendido")
    expect(page).to have_content("RSI sobrecomprado")
    expect(page).to have_content("Volumen anómalo")
    expect(page).to have_content("Dividendo próximo")
  end

  it "creates an alert rule via the chip form" do
    create(:asset, symbol: "NVDA", name: "NVIDIA Corp.", current_price: 900.0)

    visit alerts_path
    fill_in "alert[asset_symbol]", with: "NVDA"
    fill_in "alert[threshold_value]", with: "950"
    click_button "Crear alerta"

    expect(page).to have_content("NVDA")
    expect(AlertRule.where(user: user, asset_symbol: "NVDA").count).to eq(1)
  end

  it "shows the freshly created rule in the active rules table" do
    create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 200.0, status: :active)

    visit alerts_path
    expect(page).to have_content("AAPL")
    expect(page).to have_content("Precio cruza umbral")
    expect(page).to have_content("cruza USD 200 al alza")
  end

  it "toggles an alert rule from active to paused" do
    rule = create(:alert_rule, user: user, asset_symbol: "AAPL", condition: :price_crosses_above, threshold_value: 200.0, status: :active)

    page.driver.submit :patch, toggle_alert_path(rule), {}
    visit alerts_path(filter: "paused")

    expect(page).to have_content("AAPL")
    expect(rule.reload.status).to eq("paused")
  end

  it "deletes an alert rule" do
    rule = create(:alert_rule, user: user, asset_symbol: "TSLA", condition: :price_crosses_below, threshold_value: 150.0, status: :active)

    visit alerts_path
    expect(page).to have_content("TSLA")

    page.driver.delete alert_path(rule)
    visit alerts_path

    expect(page).not_to have_content("TSLA")
  end

  it "shows triggered alert events in the live feed with descriptive es-MX copy" do
    rule = create(:alert_rule, user: user, asset_symbol: "MSFT", condition: :price_crosses_above, threshold_value: 420.0, status: :active)
    create(:alert_event,
      user: user,
      alert_rule: rule,
      asset_symbol: "MSFT",
      message: "MSFT cruzó USD 420.00 al alza (precio: 421.5).",
      event_status: :triggered,
      triggered_at: 5.minutes.ago)

    visit alerts_path
    expect(page).to have_content("Disparadas recientemente")
    expect(page).to have_content("MSFT")
    expect(page).to have_content("cruzó USD 420.00 al alza")
  end

  it "renders the delivery preferences card in es-MX" do
    visit alerts_path
    expect(page).to have_content("Preferencias de entrega")
    expect(page).to have_content("Avisos en la app")
    expect(page).to have_content("Resumen diario por correo")
    expect(page).to have_content("Avisos urgentes por correo")
  end

  it "shows the tabs with active/paused/all counts" do
    create(:alert_rule, user: user, asset_symbol: "AAPL", status: :active)
    create(:alert_rule, user: user, asset_symbol: "NVDA", status: :paused)

    visit alerts_path
    expect(page).to have_content("Activas")
    expect(page).to have_content("Pausadas")
    expect(page).to have_content("Todas")
  end

  it "creates a dividend_ex_date rule with window_days" do
    create(:asset, symbol: "AAPL", name: "Apple", current_price: 200.0)

    page.driver.post alerts_path, alert: {
      asset_symbol: "AAPL",
      condition: "dividend_ex_date",
      threshold_value: 0,
      window_days: 7
    }
    visit alerts_path

    rule = AlertRule.find_by(user: user, asset_symbol: "AAPL")
    expect(rule).not_to be_nil
    expect(rule.condition).to eq("dividend_ex_date")
    expect(rule.window_days).to eq(7)
    expect(page).to have_content("Dividendo próximo")
  end
end
