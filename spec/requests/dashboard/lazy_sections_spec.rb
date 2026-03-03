require "rails_helper"

RSpec.describe "Dashboard lazy-loaded sections", type: :request do
  let!(:user) { create(:user, email: "lazydash@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "TSLA", name: "Tesla Inc.", current_price: 250.0, change_percent_24h: 3.5, asset_type: :stock, sector: "Technology", exchange: "NASDAQ", country: "US") }

  before do
    login_as(user)
    create(:watchlist_item, user: user, asset: asset)
  end

  describe "GET /dashboard" do
    it "renders lazy Turbo Frame placeholders with skeleton loaders" do
      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('id="dashboard_news_feed"')
      expect(response.body).to include('id="dashboard_trending"')
      expect(response.body).to include('loading="lazy"')
      expect(response.body).to include("animate-pulse")
    end

    it "does not render news or trending content inline" do
      create(:news_article, title: "Should not appear inline", published_at: 1.hour.ago)

      get dashboard_path

      expect(response.body).not_to include("Should not appear inline")
    end
  end

  describe "GET /dashboard/news_feed" do
    it "returns news content inside a Turbo Frame" do
      create(:news_article, title: "Tesla surges on deliveries report", related_ticker: "TSLA", source: "Reuters", published_at: 30.minutes.ago)

      get dashboard_news_feed_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dashboard_news_feed")
      expect(response.body).to include("Tesla surges on deliveries report")
      expect(response.body).to include("Reuters")
    end

    it "renders without layout" do
      get dashboard_news_feed_path

      expect(response.body).not_to include("<html")
    end
  end

  describe "GET /dashboard/trending" do
    it "returns trending stocks inside a Turbo Frame" do
      get dashboard_trending_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("dashboard_trending")
      expect(response.body).to include("TSLA")
      expect(response.body).to include("Trending Today")
    end

    it "renders without layout" do
      get dashboard_trending_path

      expect(response.body).not_to include("<html")
    end
  end
end
