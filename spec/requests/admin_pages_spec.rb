require "rails_helper"

RSpec.describe "Admin pages", type: :request do
  let(:admin_paths) { [ admin_root_path, admin_assets_path, admin_logs_path, admin_users_path ] }

  describe "authentication guard" do
    it "redirects /admin to login when not authenticated" do
      get admin_root_path
      expect(response).to redirect_to(login_path)
    end

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
      login_as(user)
    end

    it "redirects /admin to root for non-admin users" do
      get admin_root_path
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("Not authorized")
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
      login_as(admin)
    end

    it "renders the admin dashboard page" do
      create(:system_log, task_name: "Test Log", module_name: "sync")
      create(:integration, provider_name: "Polygon.io", provider_type: "Stocks & Forex")
      get admin_root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Admin Dashboard")
      expect(response.body).to include("Total Assets")
      expect(response.body).to include("Total Users")
      expect(response.body).to include("Data Integrations")
      expect(response.body).to include("Recent Logs")
    end

    it "renders the admin dashboard with sync operations panel" do
      create(:system_log, task_name: "Sync Error", module_name: "sync", severity: :error, error_message: "Timeout")
      get admin_root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sync Operations")
      expect(response.body).to include("Successful Syncs")
      expect(response.body).to include("Failed Syncs")
      expect(response.body).to include("Sync FX Rates")
    end

    it "renders the asset management page" do
      get admin_assets_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Asset Management")
      expect(response.body).to include("Total Assets")
      expect(response.body).to include("Add New Asset")
    end

    it "creates a new asset from admin" do
      expect {
        post admin_assets_path, params: {
          asset: { symbol: "NVDA", name: "NVIDIA Corporation", asset_type: "stock", country: "US" }
        }
      }.to change(Asset, :count).by(1)

      expect(response).to redirect_to(admin_assets_path)
      follow_redirect!
      expect(response.body).to include("NVDA")
    end

    it "rejects invalid asset creation" do
      post admin_assets_path, params: {
        asset: { symbol: "", name: "", asset_type: "" }
      }

      expect(response).to redirect_to(admin_assets_path)
      follow_redirect!
      expect(response.body).to include("Asset Management")
    end

    it "enqueues RefreshFxRatesJob on refresh_fx_rates" do
      expect {
        post admin_refresh_fx_rates_path
      }.to have_enqueued_job(RefreshFxRatesJob)

      expect(response).to redirect_to(admin_root_path)
    end

    it "triggers a data source sync via registry" do
      expect {
        post admin_trigger_data_source_path(key: "fx_rates")
      }.to have_enqueued_job(RefreshFxRatesJob)

      expect(response).to redirect_to(admin_root_path)
      follow_redirect!
      expect(response.body).to include("FX Rates sync enqueued")
    end

    it "returns alert for unknown data source" do
      post admin_trigger_data_source_path(key: "nonexistent")

      expect(response).to redirect_to(admin_root_path)
      follow_redirect!
      expect(response.body).to include("Unknown data source")
    end

    it "deletes an asset from admin" do
      asset = create(:asset, symbol: "TEST")

      expect {
        delete admin_asset_path(asset)
      }.to change(Asset, :count).by(-1)

      expect(response).to redirect_to(admin_assets_path)
      follow_redirect!
      expect(response.body).to include("deleted")
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
