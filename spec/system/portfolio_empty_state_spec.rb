require "rails_helper"

RSpec.describe "Portfolio empty state", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "empty@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user, buying_power: 10_000.0) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "empty@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "shows summary cards even with no positions" do
    visit portfolio_path
    expect(page).to have_content("Posiciones y movimientos")
    expect(page).to have_content("Valor total del portafolio")
    expect(page).to have_content("Saldo disponible")
  end

  it "shows the trade form on empty portfolio" do
    visit portfolio_path
    expect(page).to have_content("Registrar movimiento")
    expect(page).to have_button("Registrar movimiento", visible: :all)
  end

  it "shows header action buttons on empty portfolio" do
    visit portfolio_path
    expect(page).to have_link("Movimientos")
    expect(page).to have_link("Explorar mercado")
  end

  it "shows positions table with empty state message" do
    visit portfolio_path
    expect(page).to have_content("Aún no hay posiciones abiertas")
  end
end
