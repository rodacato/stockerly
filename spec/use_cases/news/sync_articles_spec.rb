require "rails_helper"

RSpec.describe News::SyncArticles do
  include ActiveJob::TestHelper

  let(:gateway) { instance_double(PolygonGateway) }

  before do
    allow(PolygonGateway).to receive(:new).and_return(gateway)
  end

  def article_data(n)
    {
      title: "Article #{n}",
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
      handler = class_double(LogNewsSync, call: nil)
      EventBus.subscribe(NewsSynced, handler)

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

  context "when gateway fails" do
    before do
      allow(gateway).to receive(:fetch_news)
        .and_return(Dry::Monads::Failure([ :gateway_error, "Connection timeout" ]))
    end

    it "returns Failure" do
      result = described_class.call
      expect(result).to be_failure
      expect(result.failure.first).to eq(:gateway_error)
    end

    it "does not create any articles" do
      expect { described_class.call }
        .not_to change(NewsArticle, :count)
    end
  end
end
