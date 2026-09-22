require "rails_helper"

# Locks the logo audit (#124) — every chrome surface renders the canonical
# Stockerly wordmark via `shared/_logo`. Since D139 that partial is one inline
# <svg>, so a surface that fetches the wordmark as a file is the regression.
RSpec.describe "Stockerly wordmark across surfaces", type: :system do
  before { driven_by :rack_test }

  let!(:user) { create(:user, email: "logo@test.com", password: "password123", onboarded_at: Time.current) }

  describe "public surfaces" do
    it "renders the wordmark on the landing page, inline and only once" do
      visit root_path
      expect(page).to have_css("svg[aria-label='Stockerly']", count: 1, visible: :all)
      expect(page).to have_no_css("img[src*='logo_']")
    end

    it "renders the wordmark on the login page" do
      visit login_path
      expect(page).to have_css("svg[aria-label='Stockerly']", visible: :all)
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
      expect(page).to have_css("svg[aria-label='Stockerly']", visible: :all)
    end

    it "renders the wordmark on the account screen" do
      visit edit_account_settings_path
      expect(page).to have_css("svg[aria-label='Stockerly']", visible: :all)
    end
  end
end
