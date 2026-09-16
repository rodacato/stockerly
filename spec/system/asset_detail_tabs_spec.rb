require "rails_helper"

# The two tabs of a held asset read as a segmented control: the one showing its
# panel is lit, and switching moves the light rather than stacking a second one.
RSpec.describe "Asset detail tabs", type: :system, js: true do
  let!(:user) { create(:user, email: "tabs@test.com", password: "password123", onboarded_at: Time.current) }
  let!(:asset) { create(:asset, :stock, symbol: "NVDA", currency: "USD", current_price: 120, sync_status: :active) }

  before do
    portfolio = user.portfolio || create(:portfolio, user: user)
    create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100, status: :open)

    visit login_path
    fill_in "Correo electrónico", with: "tabs@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
    visit market_asset_path(asset.symbol)
  end

  def tab(label) = find("[role='tab']", text: label)

  it "lights the tab whose panel is showing" do
    expect(tab(I18n.t("posicion.tab_analisis"))).to match_css(".bg-bg-surface[aria-selected='true']")
    expect(tab(I18n.t("posicion.tab_posicion"))).to match_css(".text-fg-subtle[aria-selected='false']")

    tab(I18n.t("posicion.tab_posicion")).click

    expect(page).to have_content(I18n.t("posicion.tu_posicion"))
    expect(tab(I18n.t("posicion.tab_posicion"))).to match_css(".bg-bg-surface.text-fg-default[aria-selected='true']")
    expect(tab(I18n.t("posicion.tab_analisis"))).not_to match_css(".bg-bg-surface, .text-fg-default, .text-primary")
  end
end
