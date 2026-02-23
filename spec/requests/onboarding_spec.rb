require "rails_helper"

RSpec.describe "Onboarding", type: :request do
  let!(:user) { create(:user, email: "onboard@example.com", password: "password123") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /onboarding/step1" do
    it "returns success" do
      get onboarding_step1_path
      expect(response).to have_http_status(:ok)
    end

    it "displays interest categories" do
      get onboarding_step1_path
      expect(response.body).to include("What markets interest you?")
      expect(response.body).to include("US Stocks")
      expect(response.body).to include("Cryptocurrency")
      expect(response.body).to include("ETFs")
    end
  end

  describe "GET /onboarding/step2" do
    let!(:aapl) { create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock) }
    let!(:nvda) { create(:asset, symbol: "NVDA", name: "NVIDIA Corp", asset_type: :stock) }

    it "returns success" do
      get onboarding_step2_path
      expect(response).to have_http_status(:ok)
    end

    it "displays stock picks from database" do
      get onboarding_step2_path
      expect(response.body).to include("Pick your first stocks to follow")
      expect(response.body).to include("AAPL")
      expect(response.body).to include("NVDA")
    end
  end

  describe "POST /onboarding/complete" do
    let!(:aapl) { create(:asset, symbol: "AAPL", name: "Apple Inc.") }
    let!(:nvda) { create(:asset, symbol: "NVDA", name: "NVIDIA Corp") }
    let!(:tsla) { create(:asset, symbol: "TSLA", name: "Tesla Inc.") }

    it "creates watchlist items and sets onboarded_at" do
      expect {
        post complete_onboarding_path, params: { asset_ids: [aapl.id, nvda.id, tsla.id] }
      }.to change { user.watchlist_items.count }.by(3)

      user.reload
      expect(user.onboarded_at).to be_present
      expect(response).to redirect_to(onboarding_step3_path)
    end
  end

  describe "POST /onboarding/skip" do
    it "sets onboarded_at and redirects to dashboard" do
      expect(user.onboarded_at).to be_nil

      post skip_onboarding_path

      user.reload
      expect(user.onboarded_at).to be_present
      expect(response).to redirect_to(dashboard_path)
    end

    it "does not create any watchlist items" do
      expect {
        post skip_onboarding_path
      }.not_to change { user.watchlist_items.count }
    end
  end

  describe "GET /onboarding/step3" do
    it "returns success" do
      get onboarding_step3_path
      expect(response).to have_http_status(:ok)
    end

    it "displays completion message" do
      get onboarding_step3_path
      expect(response.body).to include("You're all set!")
      expect(response.body).to include("Go to Dashboard")
    end
  end

  describe "onboarding redirect guard" do
    it "redirects non-onboarded user to onboarding" do
      get dashboard_path
      expect(response).to redirect_to(onboarding_step1_path)
    end

    it "allows onboarded user to access dashboard" do
      user.update!(onboarded_at: Time.current)
      get dashboard_path
      expect(response).to have_http_status(:ok)
    end
  end
end
