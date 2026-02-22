require "rails_helper"

RSpec.describe "Public pages", type: :request do
  describe "GET / (landing)" do
    it "renders successfully" do
      get root_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Stockerly")
    end
  end

  describe "GET /trends" do
    it "renders successfully with an asset" do
      create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock)
      get trends_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Trend")
    end

    it "renders with symbol search" do
      create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock)
      get trends_path(symbol: "AAPL")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AAPL")
    end

    it "renders gracefully when asset not found" do
      get trends_path(symbol: "ZZZZ")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No asset found")
    end
  end

  describe "GET /open-source" do
    it "renders successfully" do
      get open_source_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Open Source")
    end
  end

  describe "GET /privacy" do
    it "renders successfully" do
      get privacy_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Privacy")
    end
  end

  describe "GET /terms" do
    it "renders successfully" do
      get terms_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Terms")
    end
  end

  describe "GET /risk-disclosure" do
    it "renders successfully" do
      get risk_disclosure_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Risk")
    end
  end

  describe "GET /login" do
    it "renders successfully" do
      get login_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Login")
    end
  end

  describe "GET /register" do
    it "renders successfully" do
      get register_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Create your account")
    end
  end

  describe "GET /forgot-password" do
    it "renders successfully" do
      get forgot_password_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Forgot")
    end
  end
end
