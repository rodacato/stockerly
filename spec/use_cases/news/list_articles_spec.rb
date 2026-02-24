require "rails_helper"

RSpec.describe News::ListArticles do
  let!(:nvidia_article) { create(:news_article, title: "NVIDIA Record Revenue", related_ticker: "NVDA", published_at: 1.hour.ago) }
  let!(:apple_article) { create(:news_article, title: "Apple Earnings Preview", related_ticker: "AAPL", published_at: 2.hours.ago) }
  let!(:bitcoin_article) { create(:news_article, title: "Bitcoin Rally", related_ticker: "BTC", published_at: 3.hours.ago) }

  describe "#call" do
    it "returns all articles ordered by published_at desc" do
      result = described_class.call(params: {})
      expect(result).to be_success
      articles = result.value![:articles]
      expect(articles.first).to eq(nvidia_article)
    end

    it "filters by ticker" do
      result = described_class.call(params: { ticker: "AAPL" })
      articles = result.value![:articles]
      expect(articles).to include(apple_article)
      expect(articles).not_to include(nvidia_article)
    end

    it "searches by title" do
      result = described_class.call(params: { search: "bitcoin" })
      articles = result.value![:articles]
      expect(articles).to include(bitcoin_article)
      expect(articles).not_to include(nvidia_article)
    end

    it "filters by source" do
      nvidia_article.update!(source: "Bloomberg")
      apple_article.update!(source: "Reuters")

      result = described_class.call(params: { source: "Bloomberg" })
      articles = result.value![:articles]
      expect(articles).to include(nvidia_article)
      expect(articles).not_to include(apple_article)
    end

    it "filters by time_range" do
      old = create(:news_article, title: "Old News", published_at: 2.days.ago)

      result = described_class.call(params: { time_range: "24h" })
      articles = result.value![:articles]
      expect(articles).to include(nvidia_article)
      expect(articles).not_to include(old)
    end

    it "returns pagination data" do
      result = described_class.call(params: {})
      expect(result.value![:pagy]).to be_a(Pagy)
    end

    context "watchlist filter" do
      let(:user) { create(:user) }
      let(:apple_asset) { create(:asset, symbol: "AAPL") }

      before do
        create(:watchlist_item, user: user, asset: apple_asset)
      end

      it "filters articles by watchlist symbols" do
        result = described_class.call(user: user, params: { filter: "watchlist" })
        articles = result.value![:articles]
        expect(articles).to include(apple_article)
        expect(articles).not_to include(nvidia_article)
        expect(articles).not_to include(bitcoin_article)
      end

      it "returns all articles when no filter" do
        result = described_class.call(user: user, params: {})
        articles = result.value![:articles]
        expect(articles).to include(nvidia_article, apple_article, bitcoin_article)
      end

      it "returns no articles when watchlist is empty and filter active" do
        empty_user = create(:user, email: "empty@test.com")
        result = described_class.call(user: empty_user, params: { filter: "watchlist" })
        articles = result.value![:articles]
        expect(articles).to be_empty
      end
    end
  end
end
