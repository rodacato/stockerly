require "rails_helper"

# D125: the field answers as it is typed into, from the top bar of any tab.
RSpec.describe "Searching from the top bar", type: :system, js: true do
  let!(:user) { create(:user, email: "search@test.com", password: "password123", onboarded_at: Time.current) }

  before do
    create(:asset, :stock, symbol: "ALAB", name: "Astera Labs, Inc.", current_price: 142.30, sync_status: :active)

    visit login_path
    fill_in "Correo electrónico", with: "search@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    expect(page).to have_no_button("Iniciar sesión")
  end

  it "reaches a followed asset from the phone's top bar in one step" do
    visit dashboard_path
    find("a[aria-label='#{I18n.t("nav.buscar")}']").click

    find("input[name=q]").fill_in(with: "alab")

    expect(page).to have_link(href: "/market/ALAB")
    click_link href: "/market/ALAB"

    expect(page).to have_current_path("/market/ALAB")
  end
end
