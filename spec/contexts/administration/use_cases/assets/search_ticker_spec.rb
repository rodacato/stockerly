require "rails_helper"

RSpec.describe Administration::UseCases::Assets::SearchTicker do
  describe ".call" do
    before { create(:integration, provider_name: "Alpha Vantage") }

    context "with valid query" do
      before do
        stub_alpha_vantage_ticker_search("AAPL", results: [
          { "1. symbol" => "AAPL", "2. name" => "Apple Inc.", "3. type" => "Equity",
            "4. region" => "United States", "5. marketOpen" => "09:30",
            "6. marketClose" => "16:00", "7. timezone" => "UTC-04",
            "8. currency" => "USD", "9. matchScore" => "1.0000" },
          { "1. symbol" => "AAPL.MEX", "2. name" => "Apple Inc.", "3. type" => "Equity",
            "4. region" => "Mexico", "5. marketOpen" => "08:30",
            "6. marketClose" => "15:00", "7. timezone" => "UTC-06",
            "8. currency" => "MXN", "9. matchScore" => "0.5000" }
        ])
      end

      it "returns Success with mapped results" do
        result = described_class.call(query: "AAPL")

        expect(result).to be_success
        expect(result.value!.size).to eq(2)
      end

      it "maps Equity to stock asset_type" do
        result = described_class.call(query: "AAPL")
        first = result.value!.first

        expect(first[:symbol]).to eq("AAPL")
        expect(first[:name]).to eq("Apple Inc.")
        expect(first[:asset_type]).to eq("stock")
        expect(first[:exchange]).to eq("United States")
        expect(first[:country]).to eq("US")
      end

      it "maps Mexico region to MX country" do
        result = described_class.call(query: "AAPL")
        mx = result.value!.last

        expect(mx[:symbol]).to eq("AAPL.MEX")
        expect(mx[:country]).to eq("MX")
      end
    end

    context "with ETF results" do
      before do
        stub_alpha_vantage_ticker_search("SPY", results: [
          { "1. symbol" => "SPY", "2. name" => "SPDR S&P 500 ETF Trust", "3. type" => "ETF",
            "4. region" => "United States", "5. marketOpen" => "09:30",
            "6. marketClose" => "16:00", "7. timezone" => "UTC-04",
            "8. currency" => "USD", "9. matchScore" => "1.0000" }
        ])
      end

      it "maps ETF type correctly" do
        result = described_class.call(query: "SPY")

        etf = result.value!.first
        expect(etf[:asset_type]).to eq("etf")
        expect(etf[:country]).to eq("US")
      end
    end

    context "with unknown region" do
      before do
        stub_alpha_vantage_ticker_search("TSM", results: [
          { "1. symbol" => "TSM", "2. name" => "Taiwan Semiconductor", "3. type" => "Equity",
            "4. region" => "Australia", "5. marketOpen" => "10:00",
            "6. marketClose" => "16:00", "7. timezone" => "UTC+10",
            "8. currency" => "AUD", "9. matchScore" => "0.8000" }
        ])
      end

      it "falls back to nil country for unmapped regions" do
        result = described_class.call(query: "TSM")
        first = result.value!.first

        expect(first[:exchange]).to eq("Australia")
        expect(first[:country]).to be_nil
      end
    end

    context "with blank query" do
      it "returns Failure with validation error" do
        result = described_class.call(query: "")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation)
      end
    end

    context "with single character query" do
      it "returns Failure with validation error" do
        result = described_class.call(query: "A")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation)
      end
    end

    context "when gateway fails" do
      before { stub_alpha_vantage_ticker_search_error(status: 500) }

      it "propagates gateway Failure" do
        result = described_class.call(query: "AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end

    context "when rate limited" do
      before { stub_alpha_vantage_rate_limited("SYMBOL_SEARCH") }

      it "returns Failure with rate_limited" do
        result = described_class.call(query: "AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end
  end
end
