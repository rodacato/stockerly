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
      # The card states the condition in words; the bare number never meant
      # anything to a reader.
      expect(response.body).to include("cruza USD 200 al alza")
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

  describe "Rastreados lists the catalogue via Use Case" do
    let!(:user) { create(:user, email: "tracked_ref@example.com", password: "password123") }

    before do
      delete logout_path
      login_as(user)
    end

    # /admin/assets filtered by type, market and status. Rastreados does not:
    # a self-hosted catalogue capped by a 25-call daily budget fits on a screen.
    it "lists every tracked asset without a filter to reach them" do
      create(:asset, symbol: "AAPL", name: "Apple Inc.", asset_type: :stock)
      create(:asset, symbol: "BTC", name: "Bitcoin", asset_type: :crypto)

      get tracked_assets_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("AAPL")
      expect(response.body).to include("BTC")
    end
  end

  describe "Search with real results via Use Case" do
    # /search was deleted with #295; GlobalSearch was kept for the TopBar
    # search the artboards draw, so it is exercised directly.
    it "returns search results from database" do
      create(:asset, symbol: "AAPL", name: "Apple Inc.")

      result = Identity::UseCases::GlobalSearch.call(query: "AAPL", user: user)

      expect(result).to be_success
      expect(result.value![:assets].map(&:symbol)).to include("AAPL")
    end
  end
end
