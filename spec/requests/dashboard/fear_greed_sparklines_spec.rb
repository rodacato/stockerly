require "rails_helper"

RSpec.describe "Dashboard F&G inline sparklines", type: :request do
  let!(:user) { create(:user, email: "fg@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL") }

  before do
    login_as(user)
    create(:watchlist_item, user: user, asset: asset)
  end

  describe "GET /dashboard" do
    it "renders inline sparkline SVG when history data exists" do
      create(:fear_greed_reading, :crypto, value: 30, fetched_at: 2.days.ago)
      create(:fear_greed_reading, :crypto, value: 45, fetched_at: 1.day.ago)
      create(:fear_greed_reading, :crypto, value: 50, fetched_at: 1.hour.ago)

      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Crypto Fear")
      expect(response.body).to include("30-day trend")
    end

    it "does not render sparkline when history has fewer than 2 points" do
      create(:fear_greed_reading, :crypto, value: 50, fetched_at: 1.hour.ago)

      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("30-day trend")
    end

    it "passes history data to both Crypto and Stocks cards" do
      create(:fear_greed_reading, :crypto, value: 40, fetched_at: 2.days.ago)
      create(:fear_greed_reading, :crypto, value: 55, fetched_at: 1.hour.ago)
      create(:fear_greed_reading, :stocks, value: 60, fetched_at: 2.days.ago)
      create(:fear_greed_reading, :stocks, value: 70, fetched_at: 1.hour.ago)

      get dashboard_path

      expect(response.body).to include("Crypto Fear")
      expect(response.body).to include("Stocks Fear")
      expect(response.body.scan("30-day trend").size).to eq(2)
    end

    it "does not render the separate historical F&G chart section" do
      create(:fear_greed_reading, :crypto, value: 30, fetched_at: 2.days.ago)
      create(:fear_greed_reading, :crypto, value: 45, fetched_at: 1.hour.ago)

      get dashboard_path

      expect(response.body).not_to include("30 Day")
    end
  end
end
