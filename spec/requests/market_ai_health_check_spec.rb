require "rails_helper"

RSpec.describe "Market AI Health Check", type: :request do
  let!(:user) { create(:user, email: "healthcheck@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 200.0, country: "US") }
  let!(:fundamental) do
    create(:asset_fundamental, asset: asset, period_label: "OVERVIEW",
      metrics: { "eps" => "6.07", "pe_ratio" => "31.25", "profit_margin" => "0.24" })
  end

  let!(:integration) do
    create(:integration,
      provider_name: "AI Intelligence", provider_type: "AI / LLM",
      api_key_encrypted: "test-key", connection_status: :connected,
      max_requests_per_minute: 10, daily_call_limit: 200,
      settings: { "provider" => "anthropic" })
  end

  before { login_as(user) }

  describe "asset detail page" do
    context "when AI health check succeeds" do
      before do
        response = {
          health_score: 82,
          strengths: [ "Strong profit margins" ],
          concerns: [ "High valuation" ],
          summary: "Fundamentally strong company."
        }.to_json
        stub_llm_completion(content: response, provider: "anthropic")

        get market_asset_path(asset.symbol)
      end

      it "renders health check section" do
        expect(response.body).to include("AI Health Check")
        expect(response.body).to include("82")
      end

      it "shows AI-generated label" do
        expect(response.body).to include("AI-generated")
      end

      it "shows health score value" do
        expect(response.body).to include("Health Score")
      end
    end

    context "when no fundamentals exist" do
      before do
        fundamental.destroy!
        get market_asset_path(asset.symbol)
      end

      it "does not render health check section" do
        expect(response.body).not_to include("AI Health Check")
      end
    end
  end
end
