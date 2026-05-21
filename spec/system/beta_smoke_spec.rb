require "rails_helper"

# Beta-invite smoke (S10 #125 invite-prep). Walks the full path a first
# beta amigo follows from landing → register → onboard → app → logout, with
# spot-asserts on es-MX copy. If any of these break, the invite goes out on a
# half-translated or half-broken product.
#
# Intentionally end-to-end and chatty — read each step as a checklist a human
# would also verify before hitting "send" on the invite email.
RSpec.describe "Beta smoke — end to end", type: :system do
  before { driven_by :rack_test }

  # Smoke validates the *full registration flow*, including the
  # CreatePortfolioOnRegistration event handler that the global `EventBus.clear!`
  # in rails_helper.rb wipes between specs. Re-wire it here so portfolio access
  # works post-register the same way it does in production.
  before do
    EventBus.subscribe(Identity::Events::UserRegistered, Identity::Handlers::CreatePortfolioOnRegistration)
  end

  let!(:asset) { create(:asset, :stock, symbol: "NVDA", name: "NVIDIA Corp.", exchange: "NASDAQ", currency: "USD") }
  let!(:invite) { create(:invite_code) }

  it "registers, onboards, lands on dashboard, navigates every app surface, and logs out (all es-MX)" do
    # ── Landing ─────────────────────────────────────────────
    visit root_path
    expect(page).to have_css("img[alt='Stockerly']")

    # ── Register ────────────────────────────────────────────
    visit register_path
    expect(page).to have_content("Código de invitación")
    fill_in "Nombre completo",       with: "Beta Tester"
    fill_in "Correo electrónico",    with: "beta@amigo.test"
    fill_in "Contraseña",            with: "password123"
    fill_in "Confirmar contraseña",  with: "password123"
    fill_in "Código de invitación",  with: invite.code
    check "consents_data_processing"
    click_button "Crear cuenta"

    expect(page).to have_current_path(welcome_path)

    # ── Welcome → Dashboard ─────────────────────────────────
    click_button "Ir al panel"
    expect(page).to have_current_path(dashboard_path)
    expect(page).to have_content("Panel")

    # ── Navbar es-MX (regression net — these used to be English) ────
    expect(page).to have_link("Mercado")
    expect(page).to have_link("Portafolio")
    expect(page).to have_link("Alertas")
    expect(page).to have_link("Reportes")
    expect(page).to have_content("Cerrar sesión")

    # ── Market list ─────────────────────────────────────────
    click_link "Mercado", match: :first
    expect(page).to have_content("NVDA")

    # ── Asset detail ────────────────────────────────────────
    visit market_asset_path("NVDA")
    expect(page).to have_content("NVIDIA Corp.")

    # ── Earnings (es-MX header) ─────────────────────────────
    click_link "Reportes", match: :first
    expect(page).to have_content("Calendario de reportes")

    # ── Notifications inbox ─────────────────────────────────
    visit notifications_path
    expect(page).to have_content("Notificaciones")
    expect(page).to have_content("Sin notificaciones por ahora.")

    # ── Portfolio ───────────────────────────────────────────
    click_link "Portafolio", match: :first
    expect(page).to have_current_path(portfolio_path)

    # ── Profile ─────────────────────────────────────────────
    visit profile_path
    expect(page).to have_content("Beta Tester")

    # ── Logout ──────────────────────────────────────────────
    visit dashboard_path
    click_button "Cerrar sesión"
    expect(page).to have_current_path(login_path)
  end
end
