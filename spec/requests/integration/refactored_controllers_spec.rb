require "rails_helper"

RSpec.describe "Refactored controller flows", type: :request do
  let!(:user) { create(:user, email: "test@example.com", password: "password123") }

  before do
    login_as(user)
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

  describe "Profile page (S09 #97 — watchlist removed)" do
    it "loads profile successfully (watchlist no longer rendered here per S09 #97)" do
      get profile_path

      expect(response).to have_http_status(:ok)
      # The watchlist lives on /dashboard and /market now; profile is
      # purely user settings.
      expect(response.body).to include("Información personal")
    end
  end

  describe "Admin assets list via Use Case" do
    let!(:admin) { create(:user, :admin, email: "admin_ref@example.com", password: "password123") }

    before do
      delete logout_path
      login_as(admin)
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
      login_as(admin)
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
