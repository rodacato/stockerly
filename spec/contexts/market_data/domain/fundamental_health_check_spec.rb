require "rails_helper"

RSpec.describe MarketData::Domain::FundamentalHealthCheck do
  let!(:integration) do
    create(:integration,
      provider_name: "AI Intelligence", provider_type: "AI / LLM",
      api_key_encrypted: "test-key", connection_status: :connected,
      max_requests_per_minute: 10, daily_call_limit: 200,
      settings: { "provider" => "anthropic" })
  end

  let(:asset) { create(:asset, symbol: "AAPL", current_price: 200.0) }
  let(:fundamental) do
    create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
      metrics: { "eps" => "6.07", "pe_ratio" => "31.25", "profit_margin" => "0.24", "return_on_equity" => "1.57" })
  end

  describe ".analyze" do
    it "returns Success with health check on valid response" do
      response = {
        health_score: 82,
        strengths: [ "Strong profit margins", "High ROE" ],
        concerns: [ "Elevated P/E ratio" ],
        summary: "Company shows strong profitability with premium valuation."
      }.to_json
      stub_llm_completion(content: response, provider: "anthropic")

      result = described_class.analyze(asset: asset, fundamental: fundamental)

      expect(result).to be_success
      expect(result.value![:health_score]).to eq(82)
      expect(result.value![:strengths]).to include("Strong profit margins")
      expect(result.value![:concerns]).to include("Elevated P/E ratio")
    end

    it "returns Failure when no fundamentals" do
      result = described_class.analyze(asset: asset, fundamental: nil)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:no_fundamentals)
    end

    it "returns Failure when LLM fails" do
      stub_llm_error(status: 500, provider: "anthropic")

      result = described_class.analyze(asset: asset, fundamental: fundamental)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:gateway_error)
    end

    it "returns Failure on invalid JSON" do
      stub_llm_completion(content: "not json {{{", provider: "anthropic")

      result = described_class.analyze(asset: asset, fundamental: fundamental)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:parse_error)
    end

    it "prompt contains only metric values, not PII" do
      stub_llm_completion(
        content: { health_score: 50, strengths: [], concerns: [], summary: "Ok" }.to_json,
        provider: "anthropic"
      )

      described_class.analyze(asset: asset, fundamental: fundamental)

      expect(WebMock).to have_requested(:post, "https://api.anthropic.com/v1/messages")
        .with { |req|
          body = JSON.parse(req.body)
          prompt = body["messages"].first["content"]
          prompt.include?("AAPL") && prompt.include?("6.07") && !prompt.include?("@")
        }
    end

    it "clamps health score to 0-100" do
      response = { health_score: 150, strengths: [ "Strong" ], concerns: [], summary: "Good" }.to_json
      stub_llm_completion(content: response, provider: "anthropic")

      result = described_class.analyze(asset: asset, fundamental: fundamental)

      expect(result).to be_success
      expect(result.value![:health_score]).to eq(100)
    end
  end
end
