require "rails_helper"

RSpec.describe "Admin pages", type: :request do
  let(:admin_paths) { [admin_assets_path, admin_logs_path, admin_users_path] }

  describe "authentication guard" do
    it "redirects /admin/assets to login when not authenticated" do
      get admin_assets_path
      expect(response).to redirect_to(login_path)
    end

    it "redirects /admin/logs to login when not authenticated" do
      get admin_logs_path
      expect(response).to redirect_to(login_path)
    end

    it "redirects /admin/users to login when not authenticated" do
      get admin_users_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "authorization guard" do
    let!(:user) { create(:user, email: "regular@example.com", password: "password123") }

    before do
      post login_path, params: { email: user.email, password: "password123" }
    end

    it "redirects /admin/assets to root for non-admin users" do
      get admin_assets_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Not authorized")
    end

    it "redirects /admin/logs to root for non-admin users" do
      get admin_logs_path
      expect(response).to redirect_to(root_path)
    end

    it "redirects /admin/users to root for non-admin users" do
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "admin access" do
    let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }

    before do
      post login_path, params: { email: admin.email, password: "password123" }
    end

    it "renders the asset management page" do
      get admin_assets_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Asset Management")
      expect(response.body).to include("Total Assets")
    end

    it "renders the system logs page" do
      create(:system_log, task_name: "FX Rate Update", module_name: "Finance")
      get admin_logs_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("System Logs")
      expect(response.body).to include("FX Rate Update")
    end

    it "renders the users page" do
      get admin_users_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("User Management")
      expect(response.body).to include("Market Data Connectivity")
    end
  end
end
