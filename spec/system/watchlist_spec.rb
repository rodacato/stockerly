require "rails_helper"

# Watchlist add/remove specs. Per S09 #97 the watchlist embed was removed
# from /profile; the canonical surfaces are /dashboard (table) and /market
# (per-row + button to add). These specs assert against those surfaces.
RSpec.describe "Watchlist management", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "wl@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: user) }
  let!(:aapl) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 189.0, asset_type: :stock) }
  let!(:tsla) { create(:asset, symbol: "TSLA", name: "Tesla, Inc.", current_price: 176.0, asset_type: :stock) }

  before do
    visit login_path
    fill_in "Correo electrónico", with: "wl@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  it "shows assets on market page" do
    visit market_path
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

  it "shows empty watchlist state on dashboard" do
    visit dashboard_path
    # Dashboard empty state copy: from app/views/dashboard/_watchlist_table.html.erb
    expect(page).to have_content("Aún no sigues ningún activo.")
  end
end
