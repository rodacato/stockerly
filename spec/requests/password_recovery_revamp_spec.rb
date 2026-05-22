require "rails_helper"

# Password recovery revamp (S11 #147) — asserts the centered-card
# pattern matching /login + /register, the 5 dedicated states, and the
# privacy-preserving forgot-sent message.
RSpec.describe "Password recovery revamp (S11 #147)", type: :request do
  let!(:user) { create(:user, email: "recovery@example.com", password: "password123", onboarded_at: Time.current, email_verified_at: Time.current) }

  describe "GET /forgot-password (state 1 — forgot form)" do
    before { get forgot_password_path }

    it "responds 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the centered-card eyebrow + h2 + sub" do
      expect(response.body).to include("Recuperación")
      expect(response.body).to include("Recupera tu acceso")
      expect(response.body).to include("Te enviaremos un enlace al correo registrado")
    end

    it "renders the es-MX form label + CTA" do
      expect(response.body).to include("Correo electrónico")
      expect(response.body).to include("Enviar enlace")
    end

    it "links back to /login" do
      expect(response.body).to include("Inicia sesión.")
      expect(response.body).to include(login_path)
    end

    it "does NOT contain the previous split-screen branding panel copy" do
      expect(response.body).not_to include("Recupera el acceso a tu cuenta")
      expect(response.body).not_to include("Restablecimiento seguro con token único")
    end
  end

  describe "POST /forgot-password (state 2 — forgot-sent)" do
    it "renders the forgot-sent confirmation (not a redirect)" do
      post forgot_password_path, params: { email: user.email }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Revisa tu correo")
      expect(response.body).to include("Si el correo está registrado")
    end

    it "shows the same confirmation when the email is not registered (no enumeration)" do
      post forgot_password_path, params: { email: "ghost@example.com" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Revisa tu correo")
      expect(response.body).to include("Si el correo está registrado")
    end

    it "exposes the link-expiration hint" do
      post forgot_password_path, params: { email: user.email }
      expect(response.body).to include("El enlace expira en")
    end
  end

  describe "GET /reset-password/:token (state 3 — reset form)" do
    before do
      token = user.password_reset_token
      get reset_password_path(token)
    end

    it "responds 200" do
      expect(response).to have_http_status(:ok)
    end

    it "renders the centered-card eyebrow + h2 + sub" do
      expect(response.body).to include("Restablecer contraseña")
      expect(response.body).to include("Nueva contraseña")
      expect(response.body).to include("Elige una contraseña que recuerdes")
    end

    it "renders the es-MX form labels + CTA" do
      expect(response.body).to include("Nueva contraseña")
      expect(response.body).to include("Confirmar nueva contraseña")
      expect(response.body).to include("Actualizar contraseña")
    end
  end

  describe "GET /reset-password/:token with invalid token (state 4 — expired)" do
    it "renders the expired view (not a redirect+flash)" do
      get reset_password_path("invalid-token-xyz")
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Enlace inválido o expirado")
      expect(response.body).to include("Solicitar enlace nuevo")
    end
  end

  describe "PATCH /reset-password/:token success (state 5 — reset-success)" do
    it "renders the success view (not a redirect+flash)" do
      token = user.password_reset_token
      patch reset_password_path(token), params: {
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Contraseña actualizada")
      expect(response.body).to include("Ir a iniciar sesión")
    end
  end

  describe "Mailer subject (UserMailer#password_reset)" do
    it "uses the es-MX subject line — no regression on #129" do
      mail = UserMailer.password_reset(user, "https://example.com/reset/token")
      expect(mail.subject).to eq("Restablece tu contraseña de Stockerly")
    end
  end
end
