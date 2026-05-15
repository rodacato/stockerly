require "rails_helper"

RSpec.describe MarketData::Queries::RecentNews do
  describe ".call" do
    it "delegates to NewsArticle.recent (ADR-002 supplier-side wrapper)" do
      relation = double("ActiveRecord::Relation")
      allow(NewsArticle).to receive(:recent).and_return(relation)
      expect(described_class.call).to eq(relation)
    end

    it "returns articles ordered by published_at DESC end-to-end" do
      older  = create(:news_article, published_at: 2.days.ago)
      newer  = create(:news_article, published_at: 1.hour.ago)
      middle = create(:news_article, published_at: 1.day.ago)

      expect(described_class.call.to_a).to eq([ newer, middle, older ])
    end
  end
end
