require "rails_helper"

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
    fill_in "Email", with: "wl@test.com"
    fill_in "Password", with: "password123"
    click_button "Sign In"
  end

  it "shows assets on market page" do
    visit market_path
    expect(page).to have_content("Apple Inc.")
    expect(page).to have_content("Tesla, Inc.")
  end

  it "adds asset to watchlist from market page" do
    page.driver.post watchlist_items_path, asset_id: aapl.id
    visit profile_path

    expect(page).to have_content("My Watchlist")
    expect(page).to have_content("Apple Inc.")
  end

  it "shows watchlist table with watched assets on profile" do
    create(:watchlist_item, user: user, asset: aapl)
    create(:watchlist_item, user: user, asset: tsla)

    visit profile_path
    expect(page).to have_content("My Watchlist")
    expect(page).to have_content("Apple Inc.")
    expect(page).to have_content("Tesla, Inc.")
  end

  it "removes asset from watchlist on profile" do
    item = create(:watchlist_item, user: user, asset: aapl)

    visit profile_path
    expect(page).to have_content("Apple Inc.")

    page.driver.delete watchlist_item_path(item)
    visit profile_path

    expect(page).not_to have_content("Apple Inc.")
  end

  it "shows empty watchlist state" do
    visit profile_path
    expect(page).to have_content("No assets in your watchlist")
  end
end
