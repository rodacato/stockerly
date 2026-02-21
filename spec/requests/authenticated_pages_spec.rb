require "rails_helper"

RSpec.describe "Authenticated pages", type: :request do
  let!(:user) { create(:user, email: "dash@example.com", password: "password123") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /dashboard" do
    it "renders the dashboard with user name" do
      get dashboard_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Welcome back")
      expect(response.body).to include(user.full_name)
    end
  end

  describe "GET /market" do
    it "renders the market explorer with index cards" do
      get market_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("S&amp;P 500")
      expect(response.body).to include("Market Listings")
    end
  end

  describe "GET /portfolio" do
    it "renders the portfolio with allocation and positions" do
      get portfolio_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Investment Portfolio")
      expect(response.body).to include("Portfolio Allocation")
    end
  end

  describe "GET /alerts" do
    it "renders the alerts page with rules and live feed" do
      get alerts_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Trend Alerts")
      expect(response.body).to include("Live Alert Feed")
    end
  end

  describe "GET /earnings" do
    it "renders the earnings calendar" do
      get earnings_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Earnings Calendar")
      expect(response.body).to include("Watchlist Priority")
    end
  end

  describe "GET /profile" do
    it "renders the profile with user info" do
      get profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(user.full_name)
      expect(response.body).to include("Personal Information")
    end
  end
end
