require "rails_helper"

RSpec.describe NewsArticle, "sentiment scopes", type: :model do
  let!(:bullish_article) { create(:news_article, title: "Stock rises", sentiment: "bullish", sentiment_score: 80) }
  let!(:bearish_article) { create(:news_article, title: "Stock falls", sentiment: "bearish", sentiment_score: 20) }
  let!(:unanalyzed_article) { create(:news_article, title: "Breaking news", sentiment: nil) }

  it "unanalyzed scope returns articles without sentiment" do
    expect(NewsArticle.unanalyzed).to contain_exactly(unanalyzed_article)
  end

  it "bullish and bearish scopes filter correctly" do
    expect(NewsArticle.bullish).to contain_exactly(bullish_article)
    expect(NewsArticle.bearish).to contain_exactly(bearish_article)
  end
end
