require "rails_helper"

# Locks the logo audit (#124) — every chrome surface renders the canonical
# Stockerly wordmark via `shared/_logo`, and asset badges keep a fallback when
# the logo URL is missing or 404s. Regression net so a future inline-img sneaks
# back in.
RSpec.describe "Stockerly wordmark across surfaces", type: :system do
  before { driven_by :rack_test }

  let!(:user) { create(:user, email: "logo@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }

  describe "public surfaces" do
    it "renders the wordmark on the landing page" do
      visit root_path
      expect(page).to have_css("img[alt='Stockerly']")
      expect(page).to have_css("img[src*='logo_light.svg']")
      expect(page).to have_css("img[src*='logo_dark.svg']")
    end

    it "renders the wordmark on the login page" do
      visit login_path
      expect(page).to have_css("img[alt='Stockerly']")
    end
  end

  describe "authenticated surfaces" do
    before do
      visit login_path
      fill_in "Correo electrónico", with: "logo@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"
    end

    it "renders the wordmark on the dashboard navbar" do
      visit dashboard_path
      expect(page).to have_css("img[alt='Stockerly']")
    end

    it "renders the wordmark on the profile page" do
      visit profile_path
      expect(page).to have_css("img[alt='Stockerly']")
    end
  end

  describe "asset badge fallback" do
    it "renders the colored-symbol fallback when an asset has no logo_url" do
      asset = create(:asset, :stock, symbol: "FALLBACK", name: "No Logo Inc.", logo_url: nil, exchange: "NASDAQ")
      visit login_path
      fill_in "Correo electrónico", with: "logo@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"
      visit market_asset_path(asset.symbol)
      expect(page).to have_content("FALLBACK")
    end

    it "carries the onerror hook when an asset DOES have a logo_url (covers 404 case)" do
      asset = create(:asset, :stock, symbol: "WITHLOGO", name: "Has Logo Inc.", logo_url: "https://example.test/logo.png", exchange: "NASDAQ")
      visit login_path
      fill_in "Correo electrónico", with: "logo@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"
      visit market_asset_path(asset.symbol)
      expect(page.html).to include("onerror")
    end
  end
end
