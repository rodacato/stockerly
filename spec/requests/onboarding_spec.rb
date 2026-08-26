require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let!(:user) { create(:user, :admin, onboarded_at: nil) }

  before { login_as_without_onboarding(user) }

  describe "GET /onboarding/integrations" do
    let!(:integration) { create(:integration, :keyless, provider_name: "Alpaca") }

    it "renders the integrations step" do
      get onboarding_integrations_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Alpaca")
    end
  end

  describe "PATCH /onboarding/integrations" do
    let!(:integration) { create(:integration, :keyless, provider_name: "Alpaca") }

    it "saves API keys and moves to the assets step" do
      patch onboarding_save_integrations_path, params: {
        api_keys: { integration.id.to_s => "my_api_key" }
      }

      expect(response).to redirect_to(onboarding_assets_path)
      expect(integration.reload.api_key_encrypted).to eq("my_api_key")
    end
  end

  describe "GET /onboarding/assets" do
    it "renders the assets step" do
      get onboarding_assets_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /onboarding/assets" do
    it "creates the chosen assets and moves to the summary" do
      expect {
        post onboarding_save_assets_path, params: { symbols: %w[AAPL BTC] }
      }.to change(Asset, :count).by(2)

      expect(response).to redirect_to(onboarding_complete_path)
    end
  end

  describe "GET /onboarding/complete" do
    it "renders the summary" do
      get onboarding_complete_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /onboarding/launch" do
    # D30: the wizard hands over to Welcome, which is the step that marks the
    # user onboarded. Stamping it here would make Welcome unreachable, because
    # WelcomeController sends an onboarded user to the dashboard.
    it "hands over to Welcome without marking the user onboarded" do
      post onboarding_launch_path

      expect(response).to redirect_to(welcome_path)
      expect(user.reload.onboarded?).to be false
    end

    it "launches the initial sync by default" do
      create(:asset, asset_type: :stock)

      expect { post onboarding_launch_path }.to have_enqueued_job(SyncPriorityAssetsJob)
    end

    it "skips the sync when asked to" do
      create(:asset, asset_type: :stock)

      expect {
        post onboarding_launch_path, params: { launch_sync: "false" }
      }.not_to have_enqueued_job(SyncPriorityAssetsJob)
    end
  end

  describe "the whole flow, end to end" do
    it "ends at Welcome, and Welcome is what marks the user onboarded" do
      post onboarding_launch_path
      follow_redirect!
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Hola")

      post complete_welcome_path

      expect(response).to redirect_to(dashboard_path)
      expect(user.reload.onboarded?).to be true
    end
  end

  describe "guard: already onboarded" do
    before { user.update!(onboarded_at: Time.current) }

    # The negative criterion on the slice card: nothing in the flow stays
    # reachable once onboarded_at is set.
    it "sends every step to the dashboard" do
      [ onboarding_integrations_path, onboarding_assets_path, onboarding_complete_path ].each do |path|
        get path
        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
