require "rails_helper"

RSpec.describe MarketData::UseCases::SyncArticles do
  include ActiveJob::TestHelper

  let(:gateway) { instance_double(MarketData::Gateways::PolygonGateway) }

  before do
    allow(MarketData::Gateways::PolygonGateway).to receive(:new).and_return(gateway)
  end

  DISTINCT_TITLES = [
    "Apple Vision Pro Sales Exceed Expectations in First Quarter",
    "Microsoft Announces Multi-Billion Dollar AI Infrastructure Plan",
    "Tesla Shifts Focus to Next-Gen Platform for Affordable EV"
  ].freeze

  def article_data(n)
    {
      title: DISTINCT_TITLES[n - 1] || "Unique Article Number #{n}",
      summary: "Summary #{n}",
      source: "Bloomberg",
      url: "https://example.com/article-#{n}",
      image_url: "https://example.com/img-#{n}.jpg",
      published_at: n.hours.ago,
      related_ticker: "AAPL"
    }
  end

  context "when gateway returns articles" do
    before do
      allow(gateway).to receive(:fetch_news)
        .and_return(Dry::Monads::Success([ article_data(1), article_data(2), article_data(3) ]))
    end

    it "creates news articles in the database" do
      expect { described_class.call }
        .to change(NewsArticle, :count).by(3)
    end

    it "returns Success with count of created articles" do
      result = described_class.call
      expect(result).to be_success
      expect(result.value!).to eq(3)
    end

    it "publishes NewsSynced event" do
      handler = class_double(MarketData::Handlers::LogNewsSync, call: nil)
      EventBus.subscribe(MarketData::Events::NewsSynced, handler)

      described_class.call

      expect(handler).to have_received(:call).with(
        an_object_having_attributes(count: 3)
      )
    end
  end

  context "when article already exists (deduplication by URL)" do
    before do
      NewsArticle.create!(
        title: "Old", summary: "Old", source: "Reuters",
        url: "https://example.com/article-1",
        published_at: 1.day.ago
      )
      allow(gateway).to receive(:fetch_news)
        .and_return(Dry::Monads::Success([ article_data(1), article_data(2) ]))
    end

    it "only creates new articles" do
      expect { described_class.call }
        .to change(NewsArticle, :count).by(1)
    end

    it "returns count of newly created articles only" do
      result = described_class.call
      expect(result.value!).to eq(1)
    end
  end

  context "when article has blank URL" do
    before do
      blank_url = article_data(1).merge(url: "")
      allow(gateway).to receive(:fetch_news)
        .and_return(Dry::Monads::Success([ blank_url, article_data(2) ]))
    end

    it "skips articles with blank URLs" do
      expect { described_class.call }
        .to change(NewsArticle, :count).by(1)
    end
  end

  context "when articles have similar titles (deduplication by title)" do
    let(:similar_articles) do
      [
        article_data(1).merge(
          title: "Bronstein Gewirtz Urges Kyndryl Holdings Inc Investors to Act",
          url: "https://example.com/kd-lawsuit",
          related_ticker: "KD"
        ),
        article_data(2).merge(
          title: "Bronstein Gewirtz Urges Vistagen Therapeutics Inc Investors to Act",
          url: "https://example.com/vtgn-lawsuit",
          related_ticker: "VTGN"
        ),
        article_data(3).merge(
          title: "Bronstein Gewirtz Urges Enphase Energy Inc Investors to Act",
          url: "https://example.com/enph-lawsuit",
          related_ticker: "ENPH"
        )
      ]
    end

    before do
      allow(gateway).to receive(:fetch_news)
        .and_return(Dry::Monads::Success(similar_articles))
    end

    it "creates only the first article from a group of similar titles" do
      expect { described_class.call }
        .to change(NewsArticle, :count).by(1)
    end

    it "returns count reflecting deduplication" do
      result = described_class.call
      expect(result.value!).to eq(1)
    end
  end

  context "when a similar title already exists in the database" do
    before do
      NewsArticle.create!(
        title: "Bronstein Gewirtz Urges OldCorp Inc Investors to Act",
        source: "GlobeNewsWire",
        url: "https://example.com/old-lawsuit",
        published_at: 1.hour.ago
      )

      new_article = article_data(1).merge(
        title: "Bronstein Gewirtz Urges NewCorp Inc Investors to Act",
        url: "https://example.com/new-lawsuit"
      )

      allow(gateway).to receive(:fetch_news)
        .and_return(Dry::Monads::Success([ new_article ]))
    end

    it "skips the article with a similar existing title" do
      expect { described_class.call }
        .not_to change(NewsArticle, :count)
    end
  end

  context "when titles are different enough" do
    before do
      allow(gateway).to receive(:fetch_news)
        .and_return(Dry::Monads::Success([
          article_data(1).merge(title: "Apple Vision Pro Sales Exceed Expectations"),
          article_data(2).merge(title: "Microsoft Announces AI Infrastructure Plan")
        ]))
    end

    it "creates all articles with distinct titles" do
      expect { described_class.call }
        .to change(NewsArticle, :count).by(2)
    end
  end

  context "when gateway fails" do
    before do
      allow(gateway).to receive(:fetch_news)
        .and_return(Dry::Monads::Failure([ :gateway_error, "Connection timeout" ]))
    end

    it "returns Failure" do
      result = described_class.call
      expect(result).to be_failure
      expect(result.failure.first).to eq(:all_gateways_failed)
    end

    it "does not create any articles" do
      expect { described_class.call }
        .not_to change(NewsArticle, :count)
    end
  end
end
