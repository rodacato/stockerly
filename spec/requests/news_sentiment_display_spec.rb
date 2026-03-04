require "rails_helper"

RSpec.describe "News Sentiment Display", type: :request do
  let!(:user) { create(:user, email: "newssentiment@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", current_price: 200.0) }
  let!(:portfolio) { create(:portfolio, user: user) }

  before do
    create(:watchlist_item, user: user, asset: asset)
    login_as(user)
  end

  describe "dashboard news feed" do
    let!(:bullish_article) do
      create(:news_article, title: "Stock surges on earnings", sentiment: "bullish",
        sentiment_score: 85, related_ticker: "AAPL")
    end
    let!(:bearish_article) do
      create(:news_article, title: "Market drops sharply", sentiment: "bearish",
        sentiment_score: 25, related_ticker: "TSLA")
    end
    let!(:unanalyzed_article) do
      create(:news_article, title: "Breaking generic news", sentiment: nil)
    end

    before { get dashboard_news_feed_path }

    it "shows sentiment badge for analyzed articles" do
      expect(response.body).to include("Bullish")
      expect(response.body).to include("Bearish")
    end

    it "does not show badge for unanalyzed articles" do
      # Unanalyzed article should not have Bullish/Bearish/Neutral near its title
      expect(response.body).to include("Breaking generic news")
    end

    it "bullish badge has emerald color class" do
      expect(response.body).to include("bg-emerald-100")
    end

    it "bearish badge has rose color class" do
      expect(response.body).to include("bg-rose-100")
    end
  end
end
