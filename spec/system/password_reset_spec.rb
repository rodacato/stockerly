require "rails_helper"

# End-to-end through the 5 password-recovery states. Each state lives
# on its own template (per S11 #147) — assertions check the dedicated
# page content, not flash-on-redirect.
RSpec.describe "Password reset flow", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "reset@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }

  it "navigates to forgot password page from login (state 1)" do
    visit login_path
    click_link "Recupérala."
    expect(page).to have_current_path(forgot_password_path)
    expect(page).to have_content("Recupera tu acceso")
  end

  it "submits email and lands on the forgot-sent state (state 2)" do
    visit forgot_password_path
    fill_in "Correo electrónico", with: "reset@test.com"
    click_button "Enviar enlace"

    # Server renders the `sent` template inline (no redirect). The
    # URL stays at /forgot-password since the form posts there.
    expect(page).to have_current_path(forgot_password_path)
    expect(page).to have_content("Revisa tu correo")
    expect(page).to have_content("Si el correo está registrado")
  end

  it "visits reset link with valid token and shows the reset form (state 3)" do
    token = user.password_reset_token
    visit reset_password_path(token)

    expect(page).to have_content("Nueva contraseña")
    expect(page).to have_content("Elige una contraseña que recuerdes")
  end

  it "resets password with valid new password and lands on the success state (state 5)" do
    token = user.password_reset_token
    visit reset_password_path(token)

    fill_in "Nueva contraseña", with: "newpassword456"
    fill_in "Confirmar nueva contraseña", with: "newpassword456"
    click_button "Actualizar contraseña"

    expect(page).to have_content("Contraseña actualizada")
    expect(page).to have_link("Ir a iniciar sesión", href: login_path)
  end

  it "shows the expired view for an invalid token (state 4)" do
    visit reset_password_path("invalid-token-abc")

    # Stays on /reset-password/:token — does NOT redirect to /forgot-password.
    expect(page).to have_content("Enlace inválido o expirado")
    expect(page).to have_link("Solicitar enlace nuevo", href: forgot_password_path)
  end
end
