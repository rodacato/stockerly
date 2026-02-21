require "rails_helper"

RSpec.describe "Remember cookie auto-login", type: :request do
  let!(:user) { create(:user, email: "remember@example.com", password: "password123") }

  def login_with_remember
    post login_path, params: { email: user.email, password: "password123", remember: "1" }
  end

  describe "auto-login via remember cookie" do
    it "restores session from valid remember cookie" do
      login_with_remember
      remember_cookie = cookies[:remember_token]

      # Clear session but keep cookie
      reset!

      # Re-set the signed cookie on the new session
      cookies[:remember_token] = remember_cookie

      get dashboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.full_name)
    end

    it "rejects expired remember token" do
      login_with_remember
      remember_cookie = cookies[:remember_token]

      # Expire the token in DB
      RememberToken.update_all(expires_at: 1.day.ago)

      reset!
      cookies[:remember_token] = remember_cookie

      get dashboard_path
      expect(response).to redirect_to(login_path)
    end

    it "rejects tampered remember cookie" do
      login_with_remember

      reset!
      cookies[:remember_token] = "999:tampered_token_value"

      get dashboard_path
      expect(response).to redirect_to(login_path)
    end

    it "rejects cookie with missing raw token" do
      login_with_remember
      token_record = RememberToken.last

      reset!
      cookies[:remember_token] = "#{token_record.id}:"

      get dashboard_path
      expect(response).to redirect_to(login_path)
    end

    it "touches last_used_at on successful auto-login" do
      login_with_remember
      remember_cookie = cookies[:remember_token]
      token = RememberToken.last
      original_used_at = token.last_used_at

      reset!
      cookies[:remember_token] = remember_cookie

      get dashboard_path
      expect(token.reload.last_used_at).not_to eq(original_used_at)
    end

    it "rejects cookie with valid token ID but wrong digest" do
      login_with_remember
      token_record = RememberToken.last

      reset!
      cookies[:remember_token] = "#{token_record.id}:wrong_raw_token_value"

      get dashboard_path
      expect(response).to redirect_to(login_path)
    end
  end
end
