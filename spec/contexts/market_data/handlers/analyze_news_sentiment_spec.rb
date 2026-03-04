require "rails_helper"

RSpec.describe MarketData::Handlers::AnalyzeNewsSentiment do
  let!(:integration) do
    create(:integration,
      provider_name: "AI Intelligence", provider_type: "AI / LLM",
      api_key_encrypted: "test-key", connection_status: :connected,
      max_requests_per_minute: 10, daily_call_limit: 200,
      settings: { "provider" => "anthropic" })
  end

  let!(:article1) { create(:news_article, title: "Stock soars on earnings", sentiment: nil) }
  let!(:article2) { create(:news_article, title: "Market drops sharply", sentiment: nil) }

  let(:event) { double("event") }

  describe ".call" do
    it "updates articles with sentiment data" do
      response = { articles: [
        { title: "Stock soars on earnings", sentiment: "bullish", score: 85 },
        { title: "Market drops sharply", sentiment: "bearish", score: 25 }
      ] }.to_json
      stub_llm_completion(content: response, provider: "anthropic")

      described_class.call(event)

      article1.reload
      expect(article1.sentiment).to eq("bullish")
      expect(article1.sentiment_score).to eq(85)
      expect(article1.sentiment_analyzed_at).to be_present
    end

    it "only processes unanalyzed articles" do
      article1.update!(sentiment: "neutral", sentiment_score: 50, sentiment_analyzed_at: 1.hour.ago)

      response = { articles: [
        { title: "Market drops sharply", sentiment: "bearish", score: 25 }
      ] }.to_json
      stub_llm_completion(content: response, provider: "anthropic")

      described_class.call(event)

      article1.reload
      expect(article1.sentiment).to eq("neutral")
    end

    it "handles LLM failure gracefully" do
      stub_llm_error(status: 500, provider: "anthropic")

      expect { described_class.call(event) }.not_to raise_error

      article1.reload
      expect(article1.sentiment).to be_nil
    end

    it "is async" do
      expect(described_class.async?).to be true
    end
  end
end
