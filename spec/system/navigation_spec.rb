require "rails_helper"

RSpec.describe "Navigation", type: :system do
  before do
    driven_by :rack_test
  end

  describe "Public zone" do
    it "navigates from landing to trends" do
      visit root_path
      click_link "Trend Explorer"
      expect(page).to have_current_path(trends_path)
      expect(page).to have_content("Trend Explorer")
    end

    it "navigates from landing to open source" do
      visit root_path
      click_link "Open Source", match: :first
      expect(page).to have_current_path(open_source_path)
    end

    it "navigates to legal pages from footer" do
      visit root_path
      click_link "Privacy Policy"
      expect(page).to have_current_path(privacy_path)

      visit root_path
      click_link "Terms of Service"
      expect(page).to have_current_path(terms_path)

      visit root_path
      click_link "Risk Disclosure"
      expect(page).to have_current_path(risk_disclosure_path)
    end

    it "shows login and register links" do
      visit root_path
      expect(page).to have_link("Login", href: login_path)
      expect(page).to have_link("Get Started", href: register_path)
    end
  end

  describe "Auth flow" do
    it "registers and redirects to onboarding" do
      visit register_path
      fill_in "Full Name", with: "New User"
      fill_in "Email", with: "newuser@test.com"
      fill_in "Password", with: "password123"
      fill_in "Confirm Password", with: "password123"
      click_button "Create Account"

      expect(page).to have_current_path(onboarding_step1_path)
    end

    it "logs in and accesses dashboard" do
      user = create(:user, email: "login@test.com", password: "password123")
      create(:watchlist_item, user: user, asset: create(:asset))

      visit login_path
      fill_in "Email", with: "login@test.com"
      fill_in "Password", with: "password123"
      click_button "Sign In"

      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content("Dashboard")
    end

    it "logs out and returns to root" do
      user = create(:user, email: "logout@test.com", password: "password123")
      create(:watchlist_item, user: user, asset: create(:asset))

      visit login_path
      fill_in "Email", with: "logout@test.com"
      fill_in "Password", with: "password123"
      click_button "Sign In"
      expect(page).to have_current_path(dashboard_path)

      click_button "Sign Out"
      expect(page).to have_current_path(root_path)
    end
  end

  describe "App zone" do
    let!(:user) { create(:user, email: "nav@test.com", password: "password123") }
    let!(:portfolio) { create(:portfolio, user: user) }
    let!(:watchlist_item) { create(:watchlist_item, user: user, asset: create(:asset)) }

    before do
      visit login_path
      fill_in "Email", with: "nav@test.com"
      fill_in "Password", with: "password123"
      click_button "Sign In"
    end

    it "navigates to all app pages via navbar" do
      {
        "Market" => market_path,
        "Portfolio" => portfolio_path,
        "Alerts" => alerts_path,
        "Earnings" => earnings_path,
        "News" => news_path
      }.each do |label, path|
        visit dashboard_path
        click_link label, match: :first
        expect(page).to have_current_path(path)
      end
    end

    it "navigates to profile from avatar" do
      visit dashboard_path
      find("a[href='#{profile_path}']", match: :first).click
      expect(page).to have_current_path(profile_path)
    end
  end

  describe "Guards" do
    it "redirects unauthenticated users to login" do
      visit dashboard_path
      expect(page).to have_current_path(login_path)
    end

    it "redirects non-admin users from admin zone" do
      user = create(:user, email: "nonadmin@test.com", password: "password123")
      create(:watchlist_item, user: user, asset: create(:asset))

      visit login_path
      fill_in "Email", with: "nonadmin@test.com"
      fill_in "Password", with: "password123"
      click_button "Sign In"

      visit admin_assets_path
      expect(page).to have_current_path(root_path)
    end
  end

  describe "Admin zone" do
    let!(:admin) { create(:user, :admin, email: "admin@test.com", password: "password123") }
    let!(:admin_watchlist) { create(:watchlist_item, user: admin, asset: create(:asset)) }

    before do
      visit login_path
      fill_in "Email", with: "admin@test.com"
      fill_in "Password", with: "password123"
      click_button "Sign In"
    end

    it "navigates to all admin pages via sidebar" do
      visit admin_assets_path
      expect(page).to have_content("Assets")

      click_link "Logs"
      expect(page).to have_current_path(admin_logs_path)

      click_link "Users"
      expect(page).to have_current_path(admin_users_path)

      click_link "Assets"
      expect(page).to have_current_path(admin_assets_path)
    end
  end
end
