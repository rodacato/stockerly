require "rails_helper"

# Password recovery flow (S09 #99 + S11 #147). Five states render as
# dedicated views (not flash-on-redirect):
#   1. /forgot-password           GET  → new
#   2. /forgot-password           POST → sent
#   3. /reset-password/:token     GET  → edit
#   4. /reset-password/:token     GET  → expired (invalid token)
#   5. /reset-password/:token     PATCH → success
RSpec.describe "PasswordResets", type: :request do
  let!(:user) { create(:user, email: "test@example.com") }

  describe "GET /forgot-password" do
    it "renders the forgot password page" do
      get forgot_password_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Recupera tu acceso")
    end
  end

  describe "POST /forgot-password" do
    it "renders the forgot-sent page for existing email" do
      post forgot_password_path, params: { email: "test@example.com" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Revisa tu correo")
    end

    it "renders the same forgot-sent page for non-existing email (anti-enumeration)" do
      post forgot_password_path, params: { email: "nobody@example.com" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Revisa tu correo")
      # The forgot-sent copy never reveals whether the account exists.
      expect(response.body).not_to include("no encontramos")
      expect(response.body).not_to include("no existe")
    end

    it "logs the reset URL for existing user" do
      allow(Rails.logger).to receive(:info)
      post forgot_password_path, params: { email: "test@example.com" }
      expect(Rails.logger).to have_received(:info).with(/PASSWORD RESET.*reset-password/)
    end

    it "handles missing email param gracefully (still lands on the sent state)" do
      post forgot_password_path, params: {}
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Revisa tu correo")
    end
  end

  describe "GET /reset-password/:token" do
    it "renders the reset form with a valid token" do
      token = user.password_reset_token
      get reset_password_path(token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Nueva contraseña")
    end

    it "renders the expired view for an invalid token (no redirect)" do
      get reset_password_path("invalid-token")
      expect(response).to have_http_status(:not_found)
      expect(response.body).to include("Enlace inválido o expirado")
      expect(response.body).to include("Solicitar enlace nuevo")
    end
  end

  describe "PATCH /reset-password/:token" do
    let(:token) { user.password_reset_token }

    it "renders the success view on successful reset" do
      patch reset_password_path(token), params: {
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Contraseña actualizada")
      expect(user.reload.authenticate("newpassword123")).to be_truthy
    end

    it "destroys all remember tokens on password reset" do
      create(:remember_token, user: user)
      patch reset_password_path(token), params: {
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
      expect(user.remember_tokens.count).to eq(0)
    end

    it "rejects mismatched passwords" do
      patch reset_password_path(token), params: {
        password: "newpassword123",
        password_confirmation: "different"
      }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "rejects short password" do
      patch reset_password_path(token), params: {
        password: "short",
        password_confirmation: "short"
      }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "renders the expired view when the token cannot be resolved on PATCH" do
      patch reset_password_path("invalid-token"), params: {
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Enlace inválido o expirado")
    end
  end
end
