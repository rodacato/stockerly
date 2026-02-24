require "rails_helper"

RSpec.describe "EmailVerifications", type: :request do
  describe "GET /verify-email/:token" do
    let(:user) { create(:user) }

    it "verifies user and redirects with success notice" do
      token = user.generate_token_for(:email_verification)

      get verify_email_path(token)

      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("Email verified successfully!")
      expect(user.reload.email_verified_at).to be_present
    end

    it "redirects to dashboard when logged in" do
      login_as(user)
      token = user.generate_token_for(:email_verification)

      get verify_email_path(token)

      expect(response).to redirect_to(dashboard_path)
    end

    it "redirects with alert for invalid token" do
      get verify_email_path("invalid-token")

      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("Invalid or expired verification link")
    end
  end

  describe "POST /resend-verification" do
    let(:user) { create(:user) }

    it "sends verification email and redirects with notice" do
      login_as(user)
      allow(Rails.logger).to receive(:info)

      post resend_verification_path

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response.body).to include("Verification email sent")
    end

    it "redirects to login when not authenticated" do
      post resend_verification_path

      expect(response).to redirect_to(login_path)
    end

    it "redirects with notice if already verified" do
      user.update!(email_verified_at: Time.current)
      login_as(user)

      post resend_verification_path

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response.body).to include("already verified")
    end
  end
end
