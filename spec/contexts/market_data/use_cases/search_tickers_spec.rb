require "rails_helper"

RSpec.describe MarketData::UseCases::SearchTickers do
  describe ".call" do
    before { create(:integration, provider_name: "Alpha Vantage") }

    it "returns Success with the gateway's parsed results" do
      stub_alpha_vantage_ticker_search("AAPL", results: [
        { "1. symbol" => "AAPL", "2. name" => "Apple Inc.", "3. type" => "Equity",
          "4. region" => "United States", "8. currency" => "USD", "9. matchScore" => "1.0000" }
      ])

      result = described_class.call(query: "AAPL")

      expect(result).to be_success
      expect(result.value!).to be_an(Array)
      expect(result.value!.first[:symbol]).to eq("AAPL")
      expect(result.value!.first[:currency]).to eq("USD")
    end

    it "rejects blank queries" do
      result = described_class.call(query: "")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "rejects single-character queries" do
      result = described_class.call(query: "A")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "propagates gateway failures" do
      stub_alpha_vantage_ticker_search_error(status: 500)

      result = described_class.call(query: "AAPL")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:gateway_error)
    end
  end
end
