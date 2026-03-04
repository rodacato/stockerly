require "rails_helper"

RSpec.describe MarketData::UseCases::GeneratePortfolioInsight do
  let(:user) { create(:user) }
  let(:portfolio) { create(:portfolio, user: user) }
  let(:asset) { create(:asset, symbol: "AAPL", current_price: 200.0, change_percent_24h: 2.5, sector: "Technology") }

  let!(:integration) do
    create(:integration,
      provider_name: "AI Intelligence", provider_type: "AI / LLM",
      api_key_encrypted: "test-key", connection_status: :connected,
      max_requests_per_minute: 10, daily_call_limit: 200,
      settings: { "provider" => "anthropic", "model" => "claude-sonnet-4-5-20250514" })
  end

  describe ".call" do
    context "with valid portfolio" do
      before do
        create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
        stub_llm_completion(
          content: { summary: "Portfolio is tech-focused", observations: [ "Heavy in AAPL" ], risk_factors: [] }.to_json,
          provider: "anthropic"
        )
      end

      it "creates PortfolioInsight on successful generation" do
        expect { described_class.call(user: user) }.to change(PortfolioInsight, :count).by(1)

        insight = PortfolioInsight.last
        expect(insight.summary).to eq("Portfolio is tech-focused")
        expect(insight.user).to eq(user)
      end

      it "stores provider name from LLM response" do
        described_class.call(user: user)

        expect(PortfolioInsight.last.provider).to eq("anthropic")
      end
    end

    it "skips user without portfolio" do
      user_without = create(:user)

      result = described_class.call(user: user_without)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:no_portfolio)
    end

    it "returns Failure when LLM unavailable" do
      create(:position, portfolio: portfolio, asset: asset, shares: 10, status: :open)
      stub_llm_error(status: 500, provider: "anthropic")

      result = described_class.call(user: user)

      expect(result).to be_failure
    end
  end
end
