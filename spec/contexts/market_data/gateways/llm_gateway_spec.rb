require "rails_helper"

RSpec.describe MarketData::Gateways::LlmGateway do
  let(:gateway) { described_class.new }

  let!(:integration) do
    create(:integration,
      provider_name: "AI Intelligence",
      provider_type: "AI / LLM",
      pool_key_value: "test-api-key-123",
      connection_status: :connected,
      max_requests_per_minute: 10,
      daily_call_limit: 200,
      settings: { "provider" => "anthropic", "model" => "claude-sonnet-4-5-20250514" })
  end

  describe "#complete with Anthropic provider" do
    before { stub_llm_completion(content: "Test analysis response", provider: "anthropic") }

    it "returns Success with parsed response" do
      result = gateway.complete(prompt: "Analyze this data", system_prompt: "You are a financial analyst")

      expect(result).to be_success
      expect(result.value![:content]).to eq("Test analysis response")
      expect(result.value![:provider]).to eq("anthropic")
      expect(result.value![:model]).to eq("claude-sonnet-4-5-20250514")
    end
  end

  describe "#complete with OpenAI provider" do
    before do
      integration.update!(settings: { "provider" => "openai", "model" => "gpt-4o" })
      stub_llm_completion(content: "OpenAI analysis response", provider: "openai")
    end

    it "returns Success with parsed response" do
      result = described_class.new.complete(prompt: "Analyze this data")

      expect(result).to be_success
      expect(result.value![:content]).to eq("OpenAI analysis response")
      expect(result.value![:provider]).to eq("openai")
      expect(result.value![:model]).to eq("gpt-4o")
    end
  end

  describe "error handling" do
    it "returns Failure(:rate_limited) on 429" do
      stub_llm_rate_limited(provider: "anthropic")

      result = gateway.complete(prompt: "Analyze")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:rate_limited)
    end

    it "returns Failure(:gateway_error) on 500" do
      stub_llm_error(status: 500, provider: "anthropic")

      result = gateway.complete(prompt: "Analyze")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:gateway_error)
    end

    it "returns Failure(:gateway_error) on timeout" do
      stub_llm_timeout(provider: "anthropic")

      result = gateway.complete(prompt: "Analyze")

      expect(result).to be_failure
      expect(result.failure).to eq([ :gateway_error, "LLM request timed out" ])
    end
  end

  describe "when not configured" do
    it "returns Failure(:not_configured) when no Integration exists" do
      integration.destroy!
      unconfigured_gateway = described_class.new

      result = unconfigured_gateway.complete(prompt: "Analyze")

      expect(result).to be_failure
      expect(result.failure).to eq([ :not_configured, "AI Intelligence not configured" ])
    end
  end

  describe "custom base_url" do
    it "uses custom base_url from settings when provided" do
      integration.update!(settings: {
        "provider" => "openai",
        "model" => "local-model",
        "base_url" => "https://shellm.example.com"
      })
      stub_llm_completion(content: "Custom endpoint response", provider: "openai",
                          base_url: "https://shellm.example.com")

      result = described_class.new.complete(prompt: "Analyze")

      expect(result).to be_success
      expect(result.value![:content]).to eq("Custom endpoint response")
    end
  end

  describe "request body structure" do
    it "sends correct JSON body for Anthropic format" do
      anthropic_stub = stub_llm_completion(content: "Response", provider: "anthropic")

      gateway.complete(prompt: "Test prompt", system_prompt: "Be helpful", max_tokens: 500)

      expect(anthropic_stub).to have_been_requested
      expect(WebMock).to have_requested(:post, "https://api.anthropic.com/v1/messages")
        .with { |req|
          body = JSON.parse(req.body)
          body["model"] == "claude-sonnet-4-5-20250514" &&
          body["max_tokens"] == 500 &&
          body["system"] == "Be helpful" &&
          body["messages"] == [ { "role" => "user", "content" => "Test prompt" } ]
        }
    end

    it "sends correct JSON body for OpenAI format" do
      integration.update!(settings: { "provider" => "openai", "model" => "gpt-4o" })
      stub_llm_completion(content: "Response", provider: "openai")

      described_class.new.complete(prompt: "Test prompt", system_prompt: "Be helpful", max_tokens: 500)

      expect(WebMock).to have_requested(:post, "https://api.openai.com/v1/chat/completions")
        .with { |req|
          body = JSON.parse(req.body)
          body["model"] == "gpt-4o" &&
          body["max_tokens"] == 500 &&
          body["messages"] == [
            { "role" => "system", "content" => "Be helpful" },
            { "role" => "user", "content" => "Test prompt" }
          ]
        }
    end
  end
end
