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

    # The registry is the one list. A row in `integrations` that no source
    # claims is not a source, and drawing it invited the second list the
    # screen exists to remove.
    it "lists only what the registry claims" do
      create(:integration, provider_name: "Finnhub")
      create(:integration, provider_name: "Ghost provider")

      get admin_integrations_path

      expect(response.body).to include("Finnhub")
      expect(response.body).not_to include("Ghost provider")
    end

    # The defect C9 named was that this was unlabelled, not that it existed.
    it "labels the source that only works on the maintainer's key" do
      create(:integration, provider_name: "FMP", api_key_encrypted: "k")

      get admin_integrations_path

      expect(response.body).to include("31 de agosto de 2025")
    end

    it "says a source is missing its key, that the instance owns that, and what it costs" do
      create(:integration, provider_name: "Alpaca", api_key_encrypted: nil, requires_api_key: true)

      get admin_integrations_path

      expect(response.body).to include("Sin llave")
      expect(response.body).to include("Es tu instancia")
      expect(response.body).to include("dividendos y splits de tus posiciones estadounidenses")
    end

    # The distinction the screen exists for: our counter versus their refusal.
    it "separates our exhausted quota from the provider refusing us" do
      create(:integration, provider_name: "Alpha Vantage", api_key_encrypted: "k", requires_api_key: true,
                           daily_call_limit: 25, daily_api_calls: 25, calls_reset_at: Time.current)
      create(:integration, provider_name: "Yahoo Finance", requires_api_key: false,
                           last_failure_tag: "rate_limited", last_failure_at: 1.hour.ago)

      get admin_integrations_path

      expect(response.body).to include("Es tu cuota")
      expect(response.body).to include("Es el proveedor")
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
