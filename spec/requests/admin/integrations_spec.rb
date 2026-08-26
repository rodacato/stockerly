require "rails_helper"

RSpec.describe "Admin Integrations", type: :request do
  let!(:admin) { create(:user, :admin, email: "admin@example.com", password: "password123") }

  before { login_as(admin) }

  describe "PATCH /admin/integrations/:id" do
    let!(:integration) { create(:integration, provider_name: "Alpaca", daily_call_limit: 500) }

    it "updates the integration rate limits" do
      patch admin_integration_path(integration), params: {
        integration: { daily_call_limit: 1000, max_requests_per_minute: 10 }
      }

      expect(response).to redirect_to(admin_integrations_path)
      expect(integration.reload.daily_call_limit).to eq(1000)
      expect(integration.reload.max_requests_per_minute).to eq(10)
    end

    it "clears a limit back to unlimited when the field is submitted empty" do
      integration.update!(max_requests_per_minute: 10)

      patch admin_integration_path(integration), params: {
        integration: { daily_call_limit: 500, max_requests_per_minute: "" }
      }

      expect(integration.reload.max_requests_per_minute).to be_nil
      expect(integration.reload.daily_call_limit).to eq(500)
    end
  end

  describe "GET /admin/integrations" do
    it "asks Alpaca for both halves of its credential while it has none" do
      create(:integration, provider_name: "Alpaca", api_key_encrypted: nil)

      get admin_integrations_path

      expect(response.body).to include("KEY_ID:SECRET")
    end

    it "counts a paused source as a problem, not only a failed one" do
      create(:integration, provider_name: "Needs a key", api_key_encrypted: nil)
      create(:integration, :disconnected, provider_name: "Failed")
      create(:integration, provider_name: "Healthy")

      get admin_integrations_path

      expect(response.body).to include("2 con problema")
    end

    it "shows the masked key instead of the format once Alpaca has one" do
      create(:integration, provider_name: "Alpaca", api_key_encrypted: "PKTEST123:secret9999")

      get admin_integrations_path

      expect(response.body).not_to include("KEY_ID:SECRET")
      expect(response.body).to include("9999")
    end
  end

  describe "DELETE /admin/integrations/:id" do
    let!(:integration) { create(:integration, provider_name: "Old Provider") }

    it "deletes the integration" do
      expect {
        delete admin_integration_path(integration)
      }.to change(Integration, :count).by(-1)

      expect(response).to redirect_to(admin_integrations_path)
    end
  end
end
