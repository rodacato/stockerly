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

    it "displays news articles" do
      get news_path
      expect(response.body).to include("Market News")
      expect(response.body).to include("NVIDIA Surpasses Expectations")
      expect(response.body).to include("Apple Earnings Preview")
    end

    it "displays trending topics sidebar" do
      get news_path
      expect(response.body).to include("Trending Topics")
      expect(response.body).to include("AI Stocks")
      expect(response.body).to include("From Your Watchlist")
    end
  end
end
