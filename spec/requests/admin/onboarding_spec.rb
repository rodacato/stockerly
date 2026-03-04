require "rails_helper"

RSpec.describe "Admin Onboarding", type: :request do
  let!(:admin) { create(:user, :admin, onboarded_at: nil) }

  before { login_as_without_onboarding(admin) }

  describe "GET /admin/onboarding/integrations" do
    let!(:integration) { create(:integration, :keyless, provider_name: "Polygon.io") }

    it "renders integrations step" do
      get admin_onboarding_integrations_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Connect Your Data Sources")
      expect(response.body).to include("Polygon.io")
    end
  end

  describe "PATCH /admin/onboarding/integrations" do
    let!(:integration) { create(:integration, :keyless, provider_name: "Polygon.io") }

    it "saves API keys and redirects to assets step" do
      patch admin_onboarding_save_integrations_path, params: {
        api_keys: { integration.id.to_s => "my_api_key" }
      }
      expect(response).to redirect_to(admin_onboarding_assets_path)
      expect(integration.reload.api_key_encrypted).to eq("my_api_key")
    end
  end

  describe "GET /admin/onboarding/assets" do
    it "renders assets selection step" do
      get admin_onboarding_assets_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Choose Assets to Track")
    end
  end

  describe "POST /admin/onboarding/assets" do
    it "creates assets and redirects to complete step" do
      expect {
        post admin_onboarding_save_assets_path, params: { symbols: %w[AAPL BTC] }
      }.to change(Asset, :count).by(2)

      expect(response).to redirect_to(admin_onboarding_complete_path)
    end
  end

  describe "GET /admin/onboarding/complete" do
    it "renders summary page" do
      get admin_onboarding_complete_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("You're All Set!")
    end
  end

  describe "POST /admin/onboarding/launch" do
    it "marks admin as onboarded and redirects to dashboard" do
      post admin_onboarding_launch_path
      expect(response).to redirect_to(admin_root_path)
      expect(admin.reload.onboarded?).to be true
    end
  end

  describe "guard: already onboarded" do
    before { admin.update!(onboarded_at: Time.current) }

    it "redirects to admin dashboard" do
      get admin_onboarding_integrations_path
      expect(response).to redirect_to(admin_root_path)
    end
  end
end
