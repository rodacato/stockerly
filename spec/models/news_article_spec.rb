require "rails_helper"

RSpec.describe NewsArticle, type: :model do
  subject(:article) { build(:news_article) }

  describe "validations" do
    it { is_expected.to be_valid }

    it "requires title" do
      article.title = nil
      expect(article).not_to be_valid
    end

    it "requires source" do
      article.source = nil
      expect(article).not_to be_valid
    end

    it "requires published_at" do
      article.published_at = nil
      expect(article).not_to be_valid
    end
  end

  describe "scopes" do
    it ".recent returns 10 most recent articles" do
      12.times { |i| create(:news_article, published_at: i.hours.ago) }
      expect(NewsArticle.recent.count).to eq(10)
    end

    it ".for_ticker filters by related_ticker" do
      aapl = create(:news_article, related_ticker: "AAPL")
      tsla = create(:news_article, related_ticker: "TSLA")
      expect(NewsArticle.for_ticker("AAPL")).to contain_exactly(aapl)
    end

    it ".for_ticker returns all when ticker is nil" do
      create(:news_article)
      expect(NewsArticle.for_ticker(nil).count).to eq(1)
    end

    it ".for_source filters by source" do
      bloomberg = create(:news_article, source: "Bloomberg")
      reuters = create(:news_article, source: "Reuters")
      expect(NewsArticle.for_source("Bloomberg")).to contain_exactly(bloomberg)
    end

    it ".for_source returns all when source is nil" do
      create(:news_article)
      expect(NewsArticle.for_source(nil).count).to eq(1)
    end

    it ".published_after filters by time" do
      recent = create(:news_article, published_at: 30.minutes.ago)
      old = create(:news_article, published_at: 2.hours.ago)
      expect(NewsArticle.published_after(1.hour.ago)).to contain_exactly(recent)
    end

    it ".published_after returns all when time is nil" do
      create(:news_article)
      expect(NewsArticle.published_after(nil).count).to eq(1)
    end
  end
end
