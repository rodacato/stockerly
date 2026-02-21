require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let!(:user) { create(:user, email: "test@example.com", password: "password123") }

  describe "GET /login" do
    it "renders the login page" do
      get login_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome back")
    end

    it "redirects to dashboard if already logged in" do
      post login_path, params: { email: user.email, password: "password123" }
      get login_path
      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "POST /login" do
    it "logs in with valid credentials" do
      post login_path, params: { email: "test@example.com", password: "password123" }
      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response.body).to include("Welcome back")
    end

    it "rejects invalid password" do
      post login_path, params: { email: "test@example.com", password: "wrong" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Invalid email or password")
    end

    it "rejects unknown email" do
      post login_path, params: { email: "nobody@example.com", password: "password123" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Invalid email or password")
    end

    it "rejects suspended users" do
      user.update!(status: :suspended)
      post login_path, params: { email: "test@example.com", password: "password123" }
      expect(response).to redirect_to(login_path)
      follow_redirect!
      expect(response.body).to include("suspended")
    end

    it "sets remember cookie when remember=1" do
      post login_path, params: { email: "test@example.com", password: "password123", remember: "1" }
      expect(cookies[:remember_token]).to be_present
      expect(RememberToken.count).to eq(1)
    end

    it "does not set remember cookie when remember is absent" do
      post login_path, params: { email: "test@example.com", password: "password123" }
      expect(cookies[:remember_token]).to be_nil
    end

    it "handles case-insensitive email" do
      post login_path, params: { email: "TEST@EXAMPLE.COM", password: "password123" }
      expect(response).to redirect_to(dashboard_path)
    end

    it "rejects login with missing email param" do
      post login_path, params: { password: "password123" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Invalid email or password")
    end
  end

  describe "DELETE /logout" do
    before do
      post login_path, params: { email: user.email, password: "password123" }
    end

    it "logs out and redirects to root" do
      delete logout_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Signed out successfully")
    end

    it "clears remember token on logout" do
      delete logout_path # logout from before block session
      post login_path, params: { email: user.email, password: "password123", remember: "1" }
      expect(RememberToken.count).to eq(1)
      delete logout_path
      expect(RememberToken.count).to eq(0)
    end

    it "handles logout gracefully when remember token was already deleted" do
      post login_path, params: { email: user.email, password: "password123", remember: "1" }
      RememberToken.destroy_all
      delete logout_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "DELETE /logout without session" do
    it "handles logout when not logged in" do
      delete logout_path
      expect(response).to redirect_to(root_path)
    end
  end
end
