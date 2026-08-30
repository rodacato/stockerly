require "rails_helper"

# Turbo refuses a 200 response to a form POST, and the preview renders rather
# than redirects. Every request spec passed against that for as long as the
# screen has existed, because a request spec does not run Turbo -- so the
# importer's happy path had never once loaded in a browser.
RSpec.describe "Importar movimientos", type: :system, js: true do
  let!(:user) { create(:user, email: "import@test.com", password: "password123", onboarded_at: Time.current, preferred_currency: "USD") }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:vt) { create(:asset, :etf, symbol: "VT", currency: "USD") }

  let(:header) { "asset_symbol,side,shares,price_per_share,executed_at,external_id,currency" }

  before do
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2025, 12, 1), rate: 18.2293, source: "banxico")
    visit login_path
    fill_in "Correo electrónico", with: "import@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  def paste(csv)
    visit new_trade_import_path
    find("textarea").set(csv)
    click_button "Revisar"
  end

  it "reaches the summary when every symbol is known" do
    paste("#{header}\nVT,buy,2.0,100.0,2025-12-08,order-1,USD")

    expect(page).to have_content("Nada se ha guardado todavía")
    expect(page).to have_button("Importar 1 movimiento")
  end

  it "reaches the refusal when a symbol is not" do
    paste("#{header}\nNOPE,buy,1.0,10.0,2025-12-08,order-2,USD")

    expect(page).to have_content("No puedo importar todavía")
    expect(page).to have_content("NOPE")
  end

  it "imports for real from the summary" do
    paste("#{header}\nVT,buy,2.0,100.0,2025-12-08,order-1,USD")
    click_button "Importar 1 movimiento"

    expect(page).to have_current_path(portfolio_path)
    expect(Trade.count).to eq(1)
  end
end
