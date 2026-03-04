require "rails_helper"

RSpec.describe MarketData::Domain::InsightGenerator do
  let!(:integration) do
    create(:integration,
      provider_name: "AI Intelligence", provider_type: "AI / LLM",
      pool_key_value: "test-key", connection_status: :connected,
      max_requests_per_minute: 10, daily_call_limit: 200,
      settings: { "provider" => "anthropic", "model" => "claude-sonnet-4-5-20250514" })
  end

  let(:portfolio_data) do
    {
      weekly_change: 2.5,
      top_performer: { symbol: "NVDA", change_percent: 8.2 },
      worst_performer: { symbol: "TSLA", change_percent: -3.1 },
      position_count: 5,
      concentration_hhi: 1800,
      risk_level: "Moderate",
      sector_weights: { "Technology" => 60.0, "Energy" => 40.0 }
    }
  end

  describe ".generate" do
    it "returns Success with valid insight on successful LLM call" do
      llm_response = {
        summary: "Portfolio shows moderate concentration in tech.",
        observations: [ "Heavy tech exposure", "Energy provides balance" ],
        risk_factors: [ "Sector concentration risk" ]
      }.to_json

      stub_llm_completion(content: llm_response, provider: "anthropic")

      result = described_class.generate(portfolio_data: portfolio_data)

      expect(result).to be_success
      expect(result.value![:summary]).to include("tech")
      expect(result.value![:observations]).to be_an(Array)
      expect(result.value![:provider]).to eq("anthropic")
    end

    it "returns Failure when LLM gateway fails" do
      stub_llm_error(status: 500, provider: "anthropic")

      result = described_class.generate(portfolio_data: portfolio_data)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:gateway_error)
    end

    it "returns Failure when LLM response is invalid JSON" do
      stub_llm_completion(content: "not valid json {{{", provider: "anthropic")

      result = described_class.generate(portfolio_data: portfolio_data)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:parse_error)
    end

    it "returns Failure when response fails contract validation" do
      invalid_response = { summary: "", observations: [] }.to_json
      stub_llm_completion(content: invalid_response, provider: "anthropic")

      result = described_class.generate(portfolio_data: portfolio_data)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation_error)
    end

    it "system prompt contains observational-only instruction" do
      stub_llm_completion(content: { summary: "Ok", observations: [ "Test" ] }.to_json, provider: "anthropic")

      described_class.generate(portfolio_data: portfolio_data)

      expect(WebMock).to have_requested(:post, "https://api.anthropic.com/v1/messages")
        .with { |req|
          body = JSON.parse(req.body)
          body["system"]&.include?("Never recommend buying, selling")
        }
    end
  end
end
