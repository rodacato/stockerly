require "rails_helper"

RSpec.describe "Refactored controller flows", type: :request do
  let!(:user) { create(:user, email: "test@example.com", password: "password123") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "Alerts dashboard via Use Case" do
    it "loads rules, events, and preferences from database" do
      rule = create(:alert_rule, user: user, asset_symbol: "AAPL", condition: "price_crosses_above", threshold_value: 200.0)
      create(:alert_preference, user: user, email_digest: true)

      get alerts_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AAPL")
      expect(response.body).to include("200.0")
    end

    it "renders empty state when no alerts" do
      get alerts_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "Notifications via Use Case" do
    it "lists notifications and shows unread count" do
      create(:notification, user: user, title: "Price Alert: AAPL", read: false)
      create(:notification, user: user, title: "Old notification", read: true)

      get notifications_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Price Alert: AAPL")
      expect(response.body).to include("Old notification")
    end

    it "marks a single notification as read" do
      notification = create(:notification, user: user, title: "Unread", read: false)

      patch mark_as_read_notification_path(notification)

      expect(response).to redirect_to(notifications_path)
      expect(notification.reload.read).to be true
    end
  end

  describe "Profile with watchlist via Use Case" do
    it "loads profile with real watchlist items" do
      asset = create(:asset, symbol: "TSLA", name: "Tesla Inc.")
      create(:watchlist_item, user: user, asset: asset)

      get profile_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("TSLA")
    end
  end

  describe "Onboarding with DB assets via Use Case" do
    it "step2 shows real assets from database" do
      create(:asset, symbol: "GOOGL", name: "Alphabet Inc.", asset_type: :stock)
      create(:asset, symbol: "ETH", name: "Ethereum", asset_type: :crypto)

      get onboarding_step2_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("GOOGL")
      expect(response.body).to include("ETH")
    end

    it "step3 shows real watchlist progress" do
      asset = create(:asset, symbol: "AAPL")
      create(:watchlist_item, user: user, asset: asset)

      get onboarding_step3_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("1 asset")
    end
  end

  describe "Admin assets list via Use Case" do
    let!(:admin) { create(:user, :admin, email: "admin_ref@example.com", password: "password123") }

    before do
      delete logout_path
      post login_path, params: { email: admin.email, password: "password123" }
    end

    it "lists assets with filtering by type" do
      create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock)
      create(:asset, symbol: "BTC", name: "Bitcoin", asset_type: :crypto)

      get admin_assets_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AAPL")
      expect(response.body).to include("BTC")

      get admin_assets_path(type: "stock")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AAPL")
    end

    it "searches assets by name" do
      create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock)
      create(:asset, symbol: "BTC", name: "Bitcoin", asset_type: :crypto)

      get admin_assets_path(search: "apple")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AAPL")
    end
  end

  describe "Admin users list via Use Case" do
    let!(:admin) { create(:user, :admin, email: "admin_usr@example.com", password: "password123") }
    let!(:target) { create(:user, full_name: "Jane Doe", email: "jane@example.com") }

    before do
      delete logout_path
      post login_path, params: { email: admin.email, password: "password123" }
    end

    it "lists users with search" do
      get admin_users_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jane Doe")

      get admin_users_path(search: "jane")
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Jane Doe")
    end
  end

  describe "Search with real results via Use Case" do
    it "returns search results from database" do
      create(:asset, symbol: "AAPL", name: "Apple Inc.")

      get search_path(q: "AAPL")

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AAPL")
    end
  end
end
