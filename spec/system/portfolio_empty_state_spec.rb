require "rails_helper"

RSpec.describe "Portfolio empty state", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "empty@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "empty@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "says there is no curve to draw rather than showing an empty chart" do
    visit portfolio_path
    expect(page).to have_content(I18n.t("portfolios.show.sin_historial_titulo"))
  end

  it "offers the lists a way back to the Consolidado" do
    visit positions_path
    expect(page).to have_link(I18n.t("portfolios.show.titulo"))
  end

  it "shows positions table with empty state message" do
    visit positions_path
    expect(page).to have_content("Aún no hay posiciones abiertas")
  end
end
