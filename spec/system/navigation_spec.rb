require "rails_helper"

RSpec.describe "Navigation", type: :system do
  before do
    driven_by :rack_test
  end

  describe "Public zone" do
    it "redirects root to login (no public landing — closed beta)" do
      visit root_path
      expect(page).to have_current_path(login_path)
    end

    it "navigates to legal pages from login footer" do
      visit login_path
      click_link "Privacy Policy", match: :first
      expect(page).to have_current_path(privacy_path)

      visit login_path
      click_link "Terms of Service", match: :first
      expect(page).to have_current_path(terms_path)

      visit login_path
      click_link "Risk Disclosure"
      expect(page).to have_current_path(risk_disclosure_path)
    end
  end

  describe "Auth flow" do
    it "registers and redirects to welcome" do
      invite = create(:invite_code)
      visit register_path
      fill_in "Nombre completo", with: "New User"
      fill_in "Correo electrónico", with: "newuser@test.com"
      fill_in "Contraseña", with: "password123"
      fill_in "Confirmar contraseña", with: "password123"
      fill_in "Código de invitación", with: invite.code
      check "consents_data_processing"
      click_button "Crear cuenta"

      expect(page).to have_current_path(welcome_path)
    end

    it "logs in and accesses dashboard" do
      user = create(:user, email: "login@test.com", password: "password123", onboarded_at: Time.current)

      visit login_path
      fill_in "Correo electrónico", with: "login@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"

      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content("Panel")
    end

    it "logs out and lands on login (via root redirect)" do
      user = create(:user, email: "logout@test.com", password: "password123", onboarded_at: Time.current)

      visit login_path
      fill_in "Correo electrónico", with: "logout@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"
      expect(page).to have_current_path(dashboard_path)

      click_button "Cerrar sesión"
      expect(page).to have_current_path(login_path)
    end
  end

  describe "App zone" do
    let!(:user) { create(:user, email: "nav@test.com", password: "password123", onboarded_at: Time.current) }
    let!(:portfolio) { create(:portfolio, user: user) }

    before do
      visit login_path
      fill_in "Correo electrónico", with: "nav@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"
    end

    it "navigates to all app pages via navbar" do
      {
        "Mercado"   => market_path,
        "Portafolio" => portfolio_path,
        "Alertas"   => alerts_path,
        "Reportes"  => earnings_path,
        "Noticias"  => news_path
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
      user = create(:user, email: "nonadmin@test.com", password: "password123", onboarded_at: Time.current)

      visit login_path
      fill_in "Correo electrónico", with: "nonadmin@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"

      visit admin_assets_path
      # Admin guard redirects to root; route redirect bounces to /login; SessionsController
      # sees the user is logged in and forwards to /dashboard. Flash carries through.
      expect(page).to have_current_path(dashboard_path)
    end
  end

  describe "Admin zone" do
    let!(:admin) { create(:user, :admin, email: "admin@test.com", password: "password123", onboarded_at: Time.current) }

    before do
      visit login_path
      fill_in "Correo electrónico", with: "admin@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"
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
