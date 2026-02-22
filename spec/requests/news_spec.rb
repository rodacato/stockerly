require "rails_helper"

RSpec.describe "News", type: :request do
  let!(:user) { create(:user, email: "news@example.com", password: "password123") }

  before do
    post login_path, params: { email: user.email, password: "password123" }
  end

  describe "GET /news" do
    it "returns success" do
      get news_path
      expect(response).to have_http_status(:ok)
    end

    it "displays news articles from database" do
      create(:news_article, title: "NVIDIA Record Revenue", source: "Bloomberg", published_at: 1.hour.ago)
      create(:news_article, title: "Apple Earnings Preview", source: "Reuters", published_at: 2.hours.ago)

      get news_path
      expect(response.body).to include("Market News")
      expect(response.body).to include("NVIDIA Record Revenue")
      expect(response.body).to include("Apple Earnings Preview")
    end

    it "displays trending topics sidebar when articles exist" do
      create(:news_article, title: "Test Article", published_at: 1.hour.ago)
      get news_path
      expect(response.body).to include("Trending Topics")
      expect(response.body).to include("AI Stocks")
    end

    it "shows empty state when no articles" do
      get news_path
      expect(response.body).to include("No news articles yet")
    end
  end
end
