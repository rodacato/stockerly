require "rails_helper"

# The regenerate button POSTs through Turbo behind a confirm dialog, the same
# shape as the two Datos buttons -- and a request spec does not run Turbo, so
# the only proof the reader can actually reach a fresh set is a browser.
RSpec.describe "Ajustes — Seguridad", type: :system, js: true do
  let!(:user) do
    create(:user, :with_totp, email: "seguridad@test.com", password: "password123",
                              onboarded_at: Time.current, preferred_currency: "MXN")
  end

  before do
    visit login_path
    fill_in "Correo electrónico", with: "seguridad@test.com"
    fill_in "Contraseña", with: "password123"
    click_button "Iniciar sesión"

    fill_in "Código de verificación", with: ROTP::TOTP.new(user.otp_secret).now
    click_button "Verificar"
  end

  it "mints a fresh set from the hub and shows it once" do
    visit settings_path

    accept_confirm { click_button "Generar códigos nuevos" }

    expect(page).to have_content("Guarda tus códigos de recuperación")
    expect(user.otp_recovery_codes.unconsumed.count).to eq(10)
  end
end
