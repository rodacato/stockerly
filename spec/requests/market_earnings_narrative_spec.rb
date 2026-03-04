require "rails_helper"

RSpec.describe "Market Earnings Narrative", type: :request do
  let!(:user) { create(:user, email: "earningsnarr@example.com", password: "password123") }
  let!(:asset) { create(:asset, symbol: "AAPL", name: "Apple Inc.", current_price: 200.0, country: "US") }

  let!(:integration) do
    create(:integration,
      provider_name: "AI Intelligence", provider_type: "AI / LLM",
      pool_key_value: "test-key", connection_status: :connected,
      max_requests_per_minute: 10, daily_call_limit: 200,
      settings: { "provider" => "anthropic" })
  end

  before { login_as(user) }

  context "when earnings data exists" do
    before do
      create(:earnings_event, asset: asset, estimated_eps: 1.50, actual_eps: 1.65, report_date: 3.months.ago)
      create(:earnings_event, asset: asset, estimated_eps: 1.40, actual_eps: 1.52, report_date: 6.months.ago)

      response = {
        narrative: "AAPL consistently beats estimates.",
        pattern: "consistent",
        consistency_score: 85
      }.to_json
      stub_llm_completion(content: response, provider: "anthropic")

      get market_asset_earnings_tab_path(asset.symbol)
    end

    it "renders earnings narrative section" do
      expect(response.body).to include("Earnings Narrative")
      expect(response.body).to include("AAPL consistently beats estimates.")
    end
  end

  context "when no earnings data" do
    before { get market_asset_earnings_tab_path(asset.symbol) }

    it "does not render narrative" do
      expect(response.body).not_to include("Earnings Narrative")
    end
  end
end
