require "rails_helper"

# CETES detail surface (S10 #93 — Stockerly-2.0). The yield card replaces
# the tab system; copy is es-MX.
RSpec.describe "CETES detail page", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "cetes@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:cetes) do
    create(:asset, :fixed_income,
           symbol: "CETES_28D",
           name: "CETES 28 días",
           yield_rate: 11.15,
           face_value: 10.0,
           maturity_date: 20.days.from_now.to_date,
           current_price: 9.914)
  end

  before do
    visit login_path
    fill_in "Correo electrónico", with: "cetes@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "displays the yield card with annualized rate" do
    visit market_asset_path(cetes.symbol)

    expect(page).to have_content("CETES 28 días")
    expect(page).to have_content("CETE")
    expect(page).to have_content("Detalle de la emisión")
    expect(page).to have_content("11.15")
  end

  it "shows the maturity progress band and days remaining" do
    visit market_asset_path(cetes.symbol)

    expect(page).to have_content("Avance al vencimiento")
    expect(page).to have_content("20 días restantes")
  end

  it "shows the investment calculator with MXN figures" do
    visit market_asset_path(cetes.symbol)

    expect(page).to have_content("Simulación de inversión")
    expect(page).to have_content("Inversión inicial")
    expect(page).to have_content("Valor al vencimiento")
    expect(page).to have_content("Rendimiento estimado")
    expect(page).to have_content(/MXN\s/)
  end
end
