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

    it "navigates to legal pages from the login's terms line" do
      visit login_path
      click_link I18n.t("auth.privacidad"), match: :first
      expect(page).to have_current_path(privacy_path)

      visit login_path
      click_link I18n.t("auth.terminos"), match: :first
      expect(page).to have_current_path(terms_path)

      # The auth layout has no public footer, so risk disclosure is no longer
      # one click from login — the artboard's terms line carries two links. It
      # stays reachable from the legal pages, which keep that footer.
      visit privacy_path
      click_link "Risk Disclosure"
      expect(page).to have_current_path(risk_disclosure_path)
    end
  end

  describe "Auth flow" do
    it "logs in and accesses dashboard" do
      create(:user, email: "login@test.com", password: "password123", onboarded_at: Time.current)

      visit login_path
      fill_in "Correo electrónico", with: "login@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"

      expect(page).to have_current_path(dashboard_path)
      expect(page).to have_content("Panorama")
    end

    it "logs out and lands on login (via root redirect)" do
      create(:user, email: "logout@test.com", password: "password123", onboarded_at: Time.current)

      visit login_path
      fill_in "Correo electrónico", with: "logout@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"
      expect(page).to have_current_path(dashboard_path)

      # The 2.0 shell has no logout in the chrome: it lives inside Ajustes,
      # at the foot of the hub. /profile carried a second copy until D5 was
      # finally executed and the screen retired.
      visit settings_path
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

    it "navigates to the five shell destinations" do
      {
        "Panorama"  => dashboard_path,
        "Activos"   => assets_path,
        "Reglas"    => alerts_path,
        "Descubrir" => discover_path,
        "Ajustes"   => settings_path
      }.each do |label, path|
        visit dashboard_path
        click_link label, match: :first
        expect(page).to have_current_path(path)
      end
    end

    it "reaches the notification inbox from the bell" do
      visit dashboard_path
      find("a[href='#{notifications_path}']", match: :first).click
      expect(page).to have_current_path(notifications_path)
    end

    # The nav went from six entries to four, then to five when Descubrir
    # landed (D31). /market, /earnings and /news stay
    # routable but lose their entry point until their own slice decides where
    # they belong — deliberate, so a spec pins it instead of it looking like rot.
    it "no longer offers market, earnings or news in the nav" do
      visit dashboard_path

      within("nav[aria-label='Navegación principal']", match: :first) do
        expect(page).not_to have_link(href: "/market")
        expect(page).not_to have_link(href: "/earnings")
        expect(page).not_to have_link(href: "/news")
      end
    end
  end

  describe "Guards" do
    it "redirects unauthenticated users to login" do
      visit dashboard_path
      expect(page).to have_current_path(login_path)
    end

    it "redirects non-admin users from admin zone" do
      create(:user, email: "nonadmin@test.com", password: "password123", onboarded_at: Time.current)

      visit login_path
      fill_in "Correo electrónico", with: "nonadmin@test.com"
      fill_in "Contraseña", with: "password123"
      click_button "Iniciar sesión"

      visit admin_logs_path
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

    # admin.html.erb and its sidebar are gone: the instance screens render in
    # the same shell as everything else, reached from Ajustes.
    it "renders admin screens inside the app shell" do
      visit admin_settings_path
      expect(page).to have_css("nav[aria-label='Navegación principal']")

      visit admin_logs_path
      expect(page).to have_current_path(admin_logs_path)
      expect(page).to have_css("nav[aria-label='Navegación principal']")
    end
  end
end
