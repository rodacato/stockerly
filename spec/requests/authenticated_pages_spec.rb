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
      portfolio = create(:portfolio, user: user)
      asset = create(:asset)
      create(:position, portfolio: portfolio, asset: asset, shares: 10, avg_cost: 100.0)

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

  describe "POST /alerts" do
    it "creates an alert and redirects back" do
      post alerts_path, params: { alert: { asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 200.0 } }
      expect(response).to redirect_to(alerts_path)
      follow_redirect!
      expect(response.body).to include("Alert created")
    end
  end

  describe "PATCH /alerts/:id" do
    it "updates an alert and redirects back" do
      rule = create(:alert_rule, user: user)
      patch alert_path(rule), params: { alert: { asset_symbol: "TSLA", condition: "price_crosses_below", threshold_value: 150.0 } }
      expect(response).to redirect_to(alerts_path)
      follow_redirect!
      expect(response.body).to include("Alert updated")
    end
  end

  describe "DELETE /alerts/:id" do
    it "deletes an alert and redirects back" do
      rule = create(:alert_rule, user: user)
      delete alert_path(rule)
      expect(response).to redirect_to(alerts_path)
      follow_redirect!
      expect(response.body).to include("Alert deleted")
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

  describe "PATCH /profile" do
    it "updates profile and redirects back" do
      patch profile_path, params: { profile: { full_name: user.full_name, email: user.email } }
      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("Profile updated")
    end
  end

  describe "PATCH /profile/password" do
    it "changes password and redirects back" do
      patch change_password_path, params: {
        password_change: { current_password: "password123", password: "newpassword456", password_confirmation: "newpassword456" }
      }
      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("Password changed")
    end
  end
end
