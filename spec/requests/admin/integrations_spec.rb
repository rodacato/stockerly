require "rails_helper"

RSpec.describe "Admin Integrations", type: :request do
  let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }

  before { login_as(admin) }

  describe "PATCH /admin/integrations/:id" do
    let!(:integration) { create(:integration, provider_name: "Polygon.io", daily_call_limit: 500) }

    it "updates the integration rate limits" do
      patch admin_integration_path(integration), params: {
        integration: { daily_call_limit: 1000, max_requests_per_minute: 10 }
      }

      expect(response).to redirect_to(admin_users_path)
      expect(integration.reload.daily_call_limit).to eq(1000)
      expect(integration.reload.max_requests_per_minute).to eq(10)
    end
  end

  describe "DELETE /admin/integrations/:id" do
    let!(:integration) { create(:integration, provider_name: "Old Provider") }

    it "deletes the integration" do
      expect {
        delete admin_integration_path(integration)
      }.to change(Integration, :count).by(-1)

      expect(response).to redirect_to(admin_users_path)
    end
  end
end
