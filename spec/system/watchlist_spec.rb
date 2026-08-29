require "rails_helper"

# Watchlist add/remove specs. Per S09 #97 the watchlist embed was removed
# from /profile; the canonical surfaces are /dashboard (table) and /market
# (per-row + button to add). These specs assert against those surfaces.
RSpec.describe "Watchlist management", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "wl@test.com", password: "password123", onboarded_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:aapl) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 189.0, asset_type: :stock) }
  let!(:tsla) { create(:asset, symbol: "TSLA", name: "Tesla, Inc.", current_price: 176.0, asset_type: :stock) }

  # The Radar reports movement (ADR-021), and movement is now computed from two
  # daily closes rather than read off a provider column the factory happened to
  # fill. These specs are about the watchlist surfacing, so they give the assets
  # a move to have rather than asserting against one they never had.
  before do
    with_day_change(aapl, 1.25)
    with_day_change(tsla, -0.80)
  end

  before do
    visit login_path
    fill_in "Correo electrónico", with: "wl@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "shows assets on Tracked" do
    visit tracked_assets_path
    expect(page).to have_content("Apple Inc.")
    expect(page).to have_content("Tesla, Inc.")
  end

  it "adds asset to watchlist from market page and surfaces it on dashboard" do
    page.driver.post watchlist_items_path, asset_id: aapl.id
    visit dashboard_path

    expect(page).to have_content("Apple Inc.")
  end

  it "shows watchlist on dashboard with watched assets" do
    create(:watchlist_item, user: user, asset: aapl)
    create(:watchlist_item, user: user, asset: tsla)

    visit dashboard_path
    expect(page).to have_content("Apple Inc.")
    expect(page).to have_content("Tesla, Inc.")
  end

  it "removes asset from watchlist" do
    item = create(:watchlist_item, user: user, asset: aapl)

    visit dashboard_path
    expect(page).to have_content("Apple Inc.")

    page.driver.delete watchlist_item_path(item)
    visit dashboard_path

    expect(page).not_to have_content("Apple Inc.")
  end

  # The watchlist left the cockpit with the redesign: Panorama's Radar mixes
  # held and watched, and the list itself lives under Activos > Watchlist.
  it "shows the empty watchlist state under Activos" do
    visit assets_path(tab: "watchlist")

    expect(page).to have_content(I18n.t("assets.index.vacio_watchlist_titulo"))
  end
end
