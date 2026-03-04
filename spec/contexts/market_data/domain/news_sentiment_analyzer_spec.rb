require "rails_helper"

RSpec.describe MarketData::Domain::NewsSentimentAnalyzer do
  let!(:integration) do
    create(:integration,
      provider_name: "AI Intelligence", provider_type: "AI / LLM",
      api_key_encrypted: "test-key", connection_status: :connected,
      max_requests_per_minute: 10, daily_call_limit: 200,
      settings: { "provider" => "anthropic" })
  end

  ArticleStub = Struct.new(:title, :summary, keyword_init: true)

  let(:articles) do
    [
      ArticleStub.new(title: "Stock surges on earnings beat", summary: "Company exceeded expectations"),
      ArticleStub.new(title: "Market dips amid uncertainty", summary: "Investors pull back on concerns")
    ]
  end

  describe ".analyze" do
    it "returns Success with parsed sentiment for batch" do
      response = { articles: [
        { title: "Stock surges on earnings beat", sentiment: "bullish", score: 85 },
        { title: "Market dips amid uncertainty", sentiment: "bearish", score: 30 }
      ] }.to_json

      stub_llm_completion(content: response, provider: "anthropic")

      result = described_class.analyze(articles: articles)

      expect(result).to be_success
      expect(result.value!.size).to eq(2)
      expect(result.value!.first[:sentiment]).to eq("bullish")
      expect(result.value!.last[:sentiment]).to eq("bearish")
    end

    it "limits batch to 10 articles" do
      many_articles = 15.times.map { |i| ArticleStub.new(title: "Article #{i}", summary: "Summary #{i}") }
      response = { articles: 10.times.map { |i| { title: "Article #{i}", sentiment: "neutral", score: 50 } } }.to_json
      stub_llm_completion(content: response, provider: "anthropic")

      result = described_class.analyze(articles: many_articles)

      expect(result).to be_success
      expect(result.value!.size).to eq(10)
    end

    it "returns Failure when LLM fails" do
      stub_llm_error(status: 500, provider: "anthropic")

      result = described_class.analyze(articles: articles)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:gateway_error)
    end

    it "returns Failure when response is invalid JSON" do
      stub_llm_completion(content: "not json {{{", provider: "anthropic")

      result = described_class.analyze(articles: articles)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:parse_error)
    end

    it "returns Failure when contract validation fails" do
      response = { articles: [{ title: "A", sentiment: "positive", score: 50 }] }.to_json
      stub_llm_completion(content: response, provider: "anthropic")

      result = described_class.analyze(articles: articles)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation_error)
    end

    it "clamps scores to 0-100 range" do
      response = { articles: [
        { title: "Stock surges", sentiment: "bullish", score: 150 }
      ] }.to_json
      stub_llm_completion(content: response, provider: "anthropic")

      result = described_class.analyze(articles: [ articles.first ])

      expect(result).to be_success
      expect(result.value!.first[:score]).to eq(100)
    end

    it "handles empty articles array" do
      result = described_class.analyze(articles: [])

      expect(result).to be_success
      expect(result.value!).to eq([])
    end

    it "maps sentiment strings correctly" do
      response = { articles: [
        { title: "A", sentiment: "bullish", score: 80 },
        { title: "B", sentiment: "bearish", score: 20 },
        { title: "C", sentiment: "neutral", score: 50 }
      ] }.to_json
      stub_llm_completion(content: response, provider: "anthropic")

      three = 3.times.map { |i| ArticleStub.new(title: "T#{i}", summary: "S#{i}") }
      result = described_class.analyze(articles: three)

      expect(result.value!.map { |a| a[:sentiment] }).to eq(%w[bullish bearish neutral])
    end
  end
end
