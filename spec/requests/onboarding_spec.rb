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
    it "returns success" do
      get onboarding_step2_path
      expect(response).to have_http_status(:ok)
    end

    it "displays stock picks" do
      get onboarding_step2_path
      expect(response.body).to include("Pick your first stocks to follow")
      expect(response.body).to include("AAPL")
      expect(response.body).to include("NVDA")
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
end
