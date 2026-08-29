require "rails_helper"

RSpec.describe MarketData::UseCases::SearchTickers do
  describe ".call" do
    before { create(:integration, provider_name: "Yahoo Finance") }

    it "returns Success with the gateway's parsed results" do
      stub_yfinance_search("AAPL", results: [
        yfinance_match(symbol: "AAPL", name: "Apple Inc.", sector: "Technology")
      ])

      result = described_class.call(query: "AAPL")

      expect(result).to be_success
      expect(result.value!.first[:symbol]).to eq("AAPL")
      expect(result.value!.first[:exchange]).to eq("NASDAQ")
      expect(result.value!.first[:sector]).to eq("Technology")
    end

    # The provider Alpha Vantage could not serve without a key, on a query it
    # charged a call for.
    it "searches by company name, not only by ticker" do
      stub_yfinance_search("Astera Labs", results: [
        yfinance_match(symbol: "ALAB", name: "Astera Labs, Inc.")
      ])

      result = described_class.call(query: "Astera Labs")

      expect(result).to be_success
      expect(result.value!.first[:symbol]).to eq("ALAB")
    end

    it "answers an unmatched query with an empty list, not a failure" do
      stub_yfinance_search("ZZZZ", results: [])

      result = described_class.call(query: "ZZZZ")

      expect(result).to be_success
      expect(result.value!).to eq([])
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
      stub_yfinance_search_failure("AAPL")

      result = described_class.call(query: "AAPL")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:gateway_error)
    end
  end
end
