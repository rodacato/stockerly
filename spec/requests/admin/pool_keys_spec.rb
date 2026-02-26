require "rails_helper"

RSpec.describe "Admin Pool Keys", type: :request do
  let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }
  let!(:integration) { create(:integration, provider_name: "Polygon.io") }

  before { login_as(admin) }

  describe "POST /admin/integrations/:integration_id/pool_keys" do
    it "creates a new pool key" do
      expect {
        post admin_integration_pool_keys_path(integration), params: {
          api_key_pool: { name: "Production", api_key_encrypted: "pk_prod_key_123" }
        }
      }.to change(ApiKeyPool, :count).by(1)

      expect(response).to redirect_to(admin_users_path)
      expect(ApiKeyPool.last.name).to eq("Production")
    end

    it "rejects blank api key" do
      post admin_integration_pool_keys_path(integration), params: {
        api_key_pool: { name: "Empty", api_key_encrypted: "" }
      }

      expect(response).to redirect_to(admin_users_path)
      expect(flash[:alert]).to be_present
    end
  end

  describe "PATCH /admin/integrations/:integration_id/pool_keys/:id/toggle" do
    let!(:pool_key) { create(:api_key_pool, integration: integration, enabled: true) }

    it "toggles the pool key" do
      patch toggle_admin_integration_pool_key_path(integration, pool_key)
      expect(response).to redirect_to(admin_users_path)
      expect(pool_key.reload.enabled).to be false
    end
  end

  describe "DELETE /admin/integrations/:integration_id/pool_keys/:id" do
    let!(:pool_key) { create(:api_key_pool, integration: integration) }

    it "removes the pool key" do
      expect {
        delete admin_integration_pool_key_path(integration, pool_key)
      }.to change(ApiKeyPool, :count).by(-1)

      expect(response).to redirect_to(admin_users_path)
    end
  end
end
