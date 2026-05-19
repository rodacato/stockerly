require "rails_helper"

# Password recovery revamp (S09 #99) — asserts es-MX surface on both
# /forgot-password and /reset-password/:token + visible-UI consistency
# with #95 login + #96 register.
RSpec.describe "Password recovery revamp (S09 #99)", type: :request do
  let!(:user) { create(:user, email: "recovery@example.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }

  describe "GET /forgot-password" do
    before { get forgot_password_path }

    it "responds 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the es-MX heading + subtitle" do
      expect(response.body).to include("¿Olvidaste tu contraseña?")
      expect(response.body).to include("Te enviamos un enlace para restablecerla")
    end

    it "renders the es-MX branding side panel" do
      expect(response.body).to include("Recupera el acceso a tu cuenta")
      expect(response.body).to include("Restablecimiento seguro con token único")
      expect(response.body).to include("El enlace expira en 2 horas")
    end

    it "renders the es-MX form labels and CTA" do
      expect(response.body).to include("Correo electrónico")
      expect(response.body).to include("Enviar enlace")
      expect(response.body).to include("Volver al inicio de sesión")
    end

    it "does NOT contain the previous English copy" do
      expect(response.body).not_to include("Forgot your password?")
      expect(response.body).not_to include("Send Reset Link")
      expect(response.body).not_to include("Back to Login")
      expect(response.body).not_to include("Email Address")
    end
  end

  describe "POST /forgot-password" do
    it "redirects with the es-MX generic confirmation (no enumeration)" do
      post forgot_password_path, params: { email: user.email }
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("recibirás instrucciones para restablecer")
    end
  end

  describe "GET /reset-password/:token" do
    before do
      token = user.password_reset_token
      get reset_password_path(token)
    end

    it "responds 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the es-MX heading + subtitle" do
      expect(response.body).to include("Crear nueva contraseña")
      expect(response.body).to include("Ingresa tu nueva contraseña")
    end

    it "renders es-MX form labels + button" do
      expect(response.body).to include("Nueva contraseña")
      expect(response.body).to include("Confirmar nueva contraseña")
      expect(response.body).to include("Restablecer contraseña")
    end

    it "renders the es-MX requirements list" do
      expect(response.body).to include("Requisitos")
      expect(response.body).to include("Mínimo 8 caracteres")
      expect(response.body).to include("Ambas contraseñas deben coincidir")
    end

    it "does NOT contain the previous English copy" do
      expect(response.body).not_to include("Create new password")
      expect(response.body).not_to include("New Password")
      expect(response.body).not_to include("Confirm Password")
      expect(response.body).not_to include("Reset Password")
      expect(response.body).not_to include("Password requirements")
    end
  end

  describe "GET /reset-password/:token with invalid token" do
    it "redirects to forgot-password with es-MX alert" do
      get reset_password_path("invalid-token-xyz")
      expect(response).to redirect_to(forgot_password_path)
      follow_redirect!
      expect(response.body).to include("inválido o expiró")
    end
  end

  describe "Mailer subject (UserMailer#password_reset)" do
    it "uses the es-MX subject line" do
      mail = UserMailer.password_reset(user, "https://example.com/reset/token")
      expect(mail.subject).to eq("Restablece tu contraseña de Stockerly")
    end
  end
end
