require "rails_helper"

RSpec.describe "News", type: :request do
  let!(:user) { create(:user, email: "news@example.com", password: "password123") }

  before do
    login_as(user)
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

    it "renders filter bar with source buttons" do
      create(:news_article, title: "Test", published_at: 1.hour.ago)
      get news_path
      expect(response.body).to include("All News")
      expect(response.body).to include("Bloomberg")
      expect(response.body).to include("Reuters")
    end

    it "filters articles by source param" do
      create(:news_article, title: "Bloomberg Story", source: "Bloomberg", published_at: 1.hour.ago)
      create(:news_article, title: "Reuters Story", source: "Reuters", published_at: 2.hours.ago)

      get news_path(source: "Bloomberg")
      expect(response.body).to include("Bloomberg Story")
      expect(response.body).not_to include("Reuters Story")
    end

    it "filters articles by time_range param" do
      create(:news_article, title: "Recent Story", published_at: 30.minutes.ago)
      create(:news_article, title: "Old Story", published_at: 2.days.ago)

      get news_path(time_range: "24h")
      expect(response.body).to include("Recent Story")
      expect(response.body).not_to include("Old Story")
    end
  end
end
