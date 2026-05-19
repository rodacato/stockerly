require "rails_helper"

RSpec.describe "Password reset flow", type: :system do
  before do
    driven_by :rack_test
  end

  let!(:user) { create(:user, email: "reset@test.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }

  it "navigates to forgot password page from login" do
    visit login_path
    click_link "Recupérala."
    expect(page).to have_current_path(forgot_password_path)
    expect(page).to have_content("¿Olvidaste tu contraseña?")
  end

  it "submits email and sees success message" do
    visit forgot_password_path
    fill_in "Correo electrónico", with: "reset@test.com"
    click_button "Enviar enlace"

    expect(page).to have_current_path(login_path)
    expect(page).to have_content("instrucciones para restablecer")
  end

  it "visits reset link with valid token and shows form" do
    token = user.password_reset_token
    visit reset_password_path(token)

    expect(page).to have_content("Crear nueva contraseña")
  end

  it "resets password with valid new password" do
    token = user.password_reset_token
    visit reset_password_path(token)

    fill_in "Nueva contraseña", with: "newpassword456"
    fill_in "Confirmar nueva contraseña", with: "newpassword456"
    click_button "Restablecer contraseña"

    expect(page).to have_current_path(login_path)
    expect(page).to have_content("Contraseña restablecida correctamente")
  end

  it "shows error for invalid token" do
    visit reset_password_path("invalid-token-abc")

    expect(page).to have_current_path(forgot_password_path)
    expect(page).to have_content("inválido o expiró")
  end
end
