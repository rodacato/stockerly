require "rails_helper"

# Profile 2-col + IdentityCard + theme + sessions + 3-channel prefs,
# per S11 #146. Driven by rack_test (no JS).
RSpec.describe "Profile layout (S11 #146)", type: :system do
  before { driven_by :rack_test }

  let!(:user) do
    create(:user,
           email: "p146@test.com",
           full_name: "Adrian Castillo",
           password: "password123",
           onboarded_at: Time.current,
           email_verified_at: Time.current,
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
      expect(page).to have_content("Alertas activas")
    end
  end

  describe "Theme picker" do
    before { visit profile_path }

    it "renders three theme options" do
      expect(page).to have_css('[data-controller="theme"]')
      expect(page).to have_css('[data-theme-mode="light"]')
      expect(page).to have_css('[data-theme-mode="dark"]')
      expect(page).to have_css('[data-theme-mode="system"]')
    end
  end

  describe "Active sessions card" do
    it "shows a synthesized current-session row when no remember_tokens exist" do
      visit profile_path
      expect(page).to have_content("Sesiones activas")
      expect(page).to have_content("Activa ahora")
      expect(page).to have_content("Este dispositivo")
    end

    it "lists active remember_token sessions with a Cerrar sesión button" do
      RememberToken.generate(user, ip_address: "10.0.0.1", user_agent: "Mozilla/5.0 (Macintosh) Chrome/126")
      RememberToken.generate(user, ip_address: "10.0.0.2", user_agent: "Mozilla/5.0 (X11; Linux) Firefox/130")
      visit profile_path

      expect(page).to have_content("Chrome · macOS")
      expect(page).to have_content("Firefox · Linux")
      expect(page).to have_content("IP 10.0.0.1")
      expect(page).to have_content("IP 10.0.0.2")
      # Older session (non-current) gets the Cerrar sesión button
      expect(page).to have_button("Cerrar sesión")
    end

    it "revokes a session via DELETE and shows the es-MX notice" do
      token, _raw = RememberToken.generate(user, ip_address: "10.0.0.1", user_agent: "Chrome")
      RememberToken.generate(user, ip_address: "10.0.0.2", user_agent: "Firefox")  # newer = current

      page.driver.submit :delete, revoke_session_path(id: token.id), {}

      expect(user.remember_tokens.where(id: token.id)).to be_empty
      visit profile_path
      # Flash notice is consumed; the session no longer appears in the list.
      expect(page).not_to have_content("IP 10.0.0.1")
    end

    it "ignores a revoke attempt for someone else's session" do
      other_user = create(:user, email: "other@test.com", password: "password123")
      other_token, _raw = RememberToken.generate(other_user, ip_address: "10.0.0.99", user_agent: "Chrome")

      page.driver.submit :delete, revoke_session_path(id: other_token.id), {}

      expect(RememberToken.where(id: other_token.id)).to exist
    end
  end

  describe "3-channel notification preferences" do
    before { visit profile_path }

    it "renders one row per channel with a toggle" do
      expect(page).to have_content("Avisos por correo")
      expect(page).to have_content("Avisos en la app")
      expect(page).to have_content("Avisos por SMS")
      expect(page).to have_css('[data-toggle-field-value="email_digest"]')
      expect(page).to have_css('[data-toggle-field-value="browser_push"]')
      expect(page).to have_css('[data-toggle-field-value="sms_notifications"]')
    end

    it "displays the matrix-stub disclaimer about shared channels" do
      expect(page).to have_content("Pronto podrás elegir el canal por tipo de notificación.")
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
