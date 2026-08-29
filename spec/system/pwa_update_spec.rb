require "rails_helper"

# The prompt is `hidden` and also carries display utilities, so it only stays
# out of sight because Tailwind's preflight marks [hidden] !important. That is
# a load-bearing detail of a dependency, and it renders on every screen — hence
# a real browser rather than a markup assertion.
RSpec.describe "Update prompt", type: :system, js: true do
  let!(:user) { create(:user, email: "pwa@test.com", password: "password123", onboarded_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "pwa@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "stays out of sight until a waiting worker reveals it" do
    visit dashboard_path

    expect(page).to have_css("[data-controller='pwa-update']", visible: :hidden)
    expect(page).to have_no_text(I18n.t("pwa.update.aviso"))
  end
end
