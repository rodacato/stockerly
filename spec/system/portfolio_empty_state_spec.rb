require "rails_helper"

RSpec.describe "Portfolio empty state", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "empty@test.com", password: "password123", onboarded_at: Time.current) }
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

  # Historial carries no back-link of its own: the artboard's TopBar is a title
  # and nothing else, and the screen is reached from the Activos tab. Back
  # affordances on sub-screens are KIT-3's HeaderBar, not a one-off here.
  it "shows one empty state per section" do
    visit positions_path

    expect(page).to have_content("Aún no registras movimientos")
    expect(page).to have_content("Aún no has cobrado dividendos")
    expect(page).to have_content("Aún no cierras ninguna posición")
  end
end
