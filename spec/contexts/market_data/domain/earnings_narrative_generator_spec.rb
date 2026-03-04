require "rails_helper"

RSpec.describe MarketData::Domain::EarningsNarrativeGenerator do
  let!(:integration) do
    create(:integration,
      provider_name: "AI Intelligence", provider_type: "AI / LLM",
      api_key_encrypted: "test-key", connection_status: :connected,
      max_requests_per_minute: 10, daily_call_limit: 200,
      settings: { "provider" => "anthropic" })
  end

  let(:asset) { create(:asset, symbol: "AAPL", current_price: 200.0) }

  describe ".generate" do
    it "returns Success with narrative on valid response" do
      events = [
        create(:earnings_event, asset: asset, estimated_eps: 1.50, actual_eps: 1.65, report_date: 3.months.ago),
        create(:earnings_event, asset: asset, estimated_eps: 1.40, actual_eps: 1.52, report_date: 6.months.ago)
      ]

      response = {
        narrative: "AAPL has consistently beaten EPS estimates over the past 2 quarters.",
        pattern: "consistent",
        consistency_score: 90
      }.to_json
      stub_llm_completion(content: response, provider: "anthropic")

      result = described_class.generate(asset: asset, earnings_events: events)

      expect(result).to be_success
      expect(result.value![:narrative]).to include("AAPL")
      expect(result.value![:pattern]).to eq("consistent")
      expect(result.value![:consistency_score]).to eq(90)
    end

    it "returns Failure when fewer than 2 earnings events" do
      events = [ create(:earnings_event, asset: asset) ]

      result = described_class.generate(asset: asset, earnings_events: events)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:insufficient_data)
    end

    it "returns Failure when LLM fails" do
      events = [
        create(:earnings_event, asset: asset, report_date: 3.months.ago),
        create(:earnings_event, asset: asset, report_date: 6.months.ago)
      ]
      stub_llm_error(status: 500, provider: "anthropic")

      result = described_class.generate(asset: asset, earnings_events: events)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:gateway_error)
    end
  end
end
