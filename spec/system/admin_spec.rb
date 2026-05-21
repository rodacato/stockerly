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
      fill_in "Correo electrónico", with: "admin@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"
    end

    it "displays asset management page with header band" do
      visit admin_assets_path
      expect(page).to have_content("Catálogo de activos")
      expect(page).to have_content("Activos")
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
      fill_in "Correo electrónico", with: "regular@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"

      visit admin_assets_path
      expect(page).not_to have_content("Catálogo de activos")
    end
  end
end
