require "rails_helper"

RSpec.describe "Dashboard compact news feed", type: :request do
  let!(:user) { create(:user, email: "news@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL") }

  before do
    login_as(user)
    create(:watchlist_item, user: user, asset: asset)
  end

  describe "GET /dashboard" do
    it "renders news cards in compact single-line format" do
      create(:news_article, title: "Apple beats earnings", related_ticker: "AAPL", source: "Bloomberg", published_at: 1.hour.ago)

      get dashboard_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Apple beats earnings")
      expect(response.body).to include("AAPL")
      expect(response.body).to include("Bloomberg")
    end

    it "does not render image placeholders in compact news cards" do
      create(:news_article, title: "Test article", published_at: 1.hour.ago)

      get dashboard_path

      # The old design had a 'h-24 w-32' image placeholder div
      expect(response.body).not_to include("h-24 w-32")
    end

    it "renders news feed in a compact container with tight spacing" do
      create(:news_article, title: "Article 1", published_at: 1.hour.ago)
      create(:news_article, title: "Article 2", published_at: 2.hours.ago)

      get dashboard_path

      expect(response.body).to include("space-y-1")
    end
  end
end
