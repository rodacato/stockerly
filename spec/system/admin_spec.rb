require "rails_helper"

RSpec.describe "Admin asset management", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:admin) { create(:user, :admin, email: "admin@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
  let!(:portfolio) { create(:portfolio, user: admin) }
  let!(:aapl) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 189.0, asset_type: :stock, exchange: "NASDAQ", country: "US") }

  describe "as admin user" do
    before do
      visit login_path
      fill_in "Email", with: "admin@test.com"
      fill_in "Password", with: "password123"
      click_button "Sign In"
    end

    it "displays asset management page with KPI cards" do
      visit admin_assets_path
      expect(page).to have_content("Asset Management")
      expect(page).to have_content("Total Assets")
    end

    it "shows assets table with asset details" do
      visit admin_assets_path
      expect(page).to have_content("Apple Inc.")
      expect(page).to have_content("AAPL")
      expect(page).to have_content("NASDAQ")
    end

    it "creates a new asset via form" do
      visit admin_assets_path

      page.driver.post admin_assets_path, asset: {
        symbol: "GOOGL", name: "Alphabet Inc.", asset_type: "stock",
        country: "US", exchange: "NASDAQ", sector: "Technology"
      }

      visit admin_assets_path
      expect(page).to have_content("Alphabet Inc.")
      expect(page).to have_content("GOOGL")
    end

    it "toggles asset sync status" do
      expect(aapl.sync_status).to eq("active")

      page.driver.submit :patch, toggle_status_admin_asset_path(aapl), {}
      visit admin_assets_path

      expect(aapl.reload.sync_status).to eq("disabled")
    end
  end

  describe "as non-admin user" do
    let!(:regular_user) { create(:user, email: "regular@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }
    let!(:regular_portfolio) { create(:portfolio, user: regular_user) }

    it "cannot access admin zone" do
      visit login_path
      fill_in "Email", with: "regular@test.com"
      fill_in "Password", with: "password123"
      click_button "Sign In"

      visit admin_assets_path
      expect(page).not_to have_content("Asset Management")
    end
  end
end
