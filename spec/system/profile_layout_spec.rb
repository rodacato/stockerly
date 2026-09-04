require "rails_helper"

# Profile 2-col + IdentityCard + sessions, per S11 #146. Theme and the
# notification switches live on /settings. Driven by rack_test (no JS).
RSpec.describe "Profile layout (S11 #146)", type: :system do
  before { driven_by :rack_test }

  let!(:user) do
    create(:user,
           email: "p146@test.com",
           full_name: "Adrian Castillo",
           password: "password123",
           onboarded_at: Time.current,
           created_at: 1.month.ago)
  end
  let!(:portfolio) { create(:portfolio, user: user) }

  before do
    create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.0)
    create(:fx_rate, base_currency: "MXN", quote_currency: "USD", rate: 1.0 / 17.0)
    visit login_path
    fill_in "Correo electrónico", with: "p146@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"
  end

  describe "IdentityCard sidebar" do
    before { visit profile_path }

    it "renders the avatar, name, email, member-since and role badge" do
      expect(page).to have_css("aside")
      expect(page).to have_content("Adrian Castillo")
      expect(page).to have_content("p146@test.com")
      expect(page).to have_content("Miembro desde")
      expect(page).to have_content("Usuario")
    end

    it "renders the lightweight stats list (counts only)" do
      expect(page).to have_content("Posiciones abiertas")
      expect(page).to have_content("Activos en watchlist")
      expect(page).to have_content("Reglas activas")
    end
  end

  describe "Ajustes owns the preferences" do
    before { visit settings_path }

    it "renders the theme options and both email switches once, on the hub" do
      expect(page).to have_css('[data-theme-mode="light"]')
      expect(page).to have_css('[data-theme-mode="dark"]')
      expect(page).to have_css('[data-theme-mode="system"]')
      expect(page).to have_css('[data-toggle-field-value="email_digest"]')
      expect(page).to have_css('[data-toggle-field-value="urgent_email"]')
    end

    it "leaves none of them on the profile" do
      visit profile_path

      expect(page).to have_no_css('[data-controller="theme"]')
      expect(page).to have_no_css("[data-toggle-field-value]", visible: :all)
      expect(page).to have_no_content("Moneda preferida")
    end
  end

  describe "2-col responsive layout" do
    before { visit profile_path }

    it "uses a md:grid-cols-12 split with the IdentityCard on the left" do
      expect(page.body).to include("md:grid-cols-12")
      expect(page.body).to include("md:col-span-4")
      expect(page.body).to include("md:col-span-8")
    end
  end
end
