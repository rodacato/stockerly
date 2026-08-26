require "rails_helper"

RSpec.describe "Admin pages", type: :request do
  describe "authentication guard" do
    it "redirects /admin/settings to login when not authenticated" do
      get admin_settings_path
      expect(response).to redirect_to(login_path)
    end

    it "redirects /admin/logs to login when not authenticated" do
      get admin_logs_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "authorization guard" do
    let!(:user) { create(:user, email: "regular@example.com", password: "password123") }

    before do
      login_as(user)
    end

    it "redirects /admin/settings to root for non-admin users" do
      get admin_settings_path
      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq("No tienes acceso a esa sección.")
    end

    it "redirects /admin/logs to root for non-admin users" do
      get admin_logs_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "admin access" do
    let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }

    before do
      login_as(admin)
    end

    it "offers every registered source as a manual trigger on Estado" do
      get admin_settings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sincronización manual")
      expect(response.body).to include("FX Rates")
    end

    it "triggers a data source sync via registry" do
      expect {
        post admin_trigger_data_source_path(key: "fx_rates")
      }.to have_enqueued_job(RefreshFxRatesJob)

      expect(response).to redirect_to(admin_settings_path)
      follow_redirect!
      expect(response.body).to include("Sincronización de FX Rates encolada.")
    end

    it "returns alert for unknown data source" do
      post admin_trigger_data_source_path(key: "nonexistent")

      expect(response).to redirect_to(admin_settings_path)
      follow_redirect!
      expect(response.body).to include("Fuente de datos desconocida.")
    end

    it "renders the system logs page" do
      create(:system_log, task_name: "FX Rate Update", module_name: "Finance")
      get admin_logs_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Registros")
      expect(response.body).to include("FX Rate Update")
    end

    it "renders the integrations page" do
      get admin_integrations_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("De dónde salen tus precios")
    end
  end
end
