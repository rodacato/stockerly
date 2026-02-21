require "rails_helper"

RSpec.describe "PasswordResets", type: :request do
  let!(:user) { create(:user, email: "test@example.com") }

  describe "GET /forgot-password" do
    it "renders the forgot password page" do
      get forgot_password_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Forgot your password?")
    end
  end

  describe "POST /forgot-password" do
    it "redirects with generic message for existing email" do
      post forgot_password_path, params: { email: "test@example.com" }
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("reset instructions")
    end

    it "redirects with same message for non-existing email (anti-enumeration)" do
      post forgot_password_path, params: { email: "nobody@example.com" }
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("reset instructions")
    end

    it "logs the reset URL for existing user" do
      allow(Rails.logger).to receive(:info)
      post forgot_password_path, params: { email: "test@example.com" }
      expect(Rails.logger).to have_received(:info).with(/PASSWORD RESET.*reset-password/)
    end

    it "handles missing email param gracefully" do
      post forgot_password_path, params: {}
      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET /reset-password/:token" do
    it "renders reset form with valid token" do
      token = user.password_reset_token
      get reset_password_path(token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create new password")
    end

    it "redirects for invalid token" do
      get reset_password_path("invalid-token")
      expect(response).to redirect_to(forgot_password_path)
    end
  end

  describe "PATCH /reset-password/:token" do
    let(:token) { user.password_reset_token }

    it "resets password and redirects to login" do
      patch reset_password_path(token), params: {
        password: "newpassword123",
        password_confirmation: "newpassword123"
      }
      expect(response).to redirect_to(login_path)
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
  end
end
