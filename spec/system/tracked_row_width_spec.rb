require "rails_helper"

# The widest row Tracked renders: a paused asset on the cheapest tier carries
# the tier chip, EN PAUSA, Seguir, Reanudar and delete. On a 390px phone its
# symbol line has to wrap, or the card sets the page wider than the screen.
RSpec.describe "Tracked row on a phone", type: :system, js: true do
  let!(:user) { create(:user, email: "narrow@test.com", password: "password123", onboarded_at: Time.current) }

  before do
    create(:portfolio, user: user)
    create(:asset, :stock, symbol: "NVAX", name: "Novavax", sync_status: :disabled)
    visit login_path
    fill_in "Correo electrónico", with: "narrow@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "keeps a paused, untiered row inside the screen" do
    visit tracked_assets_path

    expect(page).to have_text("EN PAUSA")
    expect(page.evaluate_script("document.documentElement.scrollWidth")).to be <= 390
  end
end
