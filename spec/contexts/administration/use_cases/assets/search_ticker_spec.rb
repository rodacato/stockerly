require "rails_helper"

RSpec.describe Administration::UseCases::Assets::SearchTicker do
  describe ".call" do
    let!(:integration) do
      create(:integration, provider_name: "Yahoo Finance",
             max_requests_per_minute: 6, daily_call_limit: 200)
    end

    context "with valid query" do
      before do
        stub_yfinance_search("AAPL", results: [
          yfinance_match(symbol: "AAPL", name: "Apple Inc.", exchange: "NASDAQ", sector: "Technology"),
          yfinance_match(symbol: "AAPL.MX", name: "Apple Inc.", exchange: "Mexico")
        ])
      end

      it "returns Success with mapped results" do
        result = described_class.call(query: "AAPL")

        expect(result).to be_success
        expect(result.value!.size).to eq(2)
      end

      it "maps EQUITY to stock asset_type" do
        first = described_class.call(query: "AAPL").value!.first

        expect(first[:symbol]).to eq("AAPL")
        expect(first[:name]).to eq("Apple Inc.")
        expect(first[:asset_type]).to eq("stock")
        expect(first[:exchange]).to eq("NASDAQ")
        expect(first[:country]).to eq("US")
      end

      it "maps the Mexican listing to MX and MXN" do
        mx = described_class.call(query: "AAPL").value!.last

        expect(mx[:symbol]).to eq("AAPL.MX")
        expect(mx[:country]).to eq("MX")
        expect(mx[:currency]).to eq("MXN")
      end

      # Alpha Vantage never returned a sector, so the field on the Agregar
      # activo form was always left for the owner to type.
      it "carries the sector the provider already knows" do
        expect(described_class.call(query: "AAPL").value!.first[:sector]).to eq("Technology")
      end
    end

    it "maps ETF results to the etf type" do
      stub_yfinance_search("ESGU", results: [
        yfinance_match(symbol: "ESGU", name: "iShares ESG Aware MSCI USA ETF", quote_type: "ETF")
      ])

      etf = described_class.call(query: "ESGU").value!.first

      expect(etf[:asset_type]).to eq("etf")
      expect(etf[:country]).to eq("US")
    end

    it "maps a German venue Yahoo names differently than Alpha Vantage did" do
      stub_yfinance_search("Astera Labs", results: [
        yfinance_match(symbol: "64B.DE", name: "Astera Labs, Inc.", exchange: "XETRA")
      ])

      expect(described_class.call(query: "Astera Labs").value!.first[:country]).to eq("DE")
    end

    # Yahoo sends no currency at all, so an unmapped venue cannot inherit one.
    # USD is the deliberate floor, and Mexico is what had to be mapped.
    it "leaves an unmapped venue without a country, priced in USD" do
      stub_yfinance_search("PTT", results: [
        yfinance_match(symbol: "PTT.BK", name: "PTT Public Company", exchange: "SET")
      ])

      first = described_class.call(query: "PTT").value!.first

      expect(first[:exchange]).to eq("SET")
      expect(first[:country]).to be_nil
      expect(first[:currency]).to eq("USD")
    end

    it "returns Failure with validation error for a blank query" do
      result = described_class.call(query: "")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "returns Failure with validation error for a single character" do
      result = described_class.call(query: "A")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:validation)
    end

    it "propagates gateway Failure" do
      stub_yfinance_search_failure("AAPL")

      result = described_class.call(query: "AAPL")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:gateway_error)
    end

    it "refuses once the provider's minute ceiling is spent" do
      integration.update!(minute_calls: 6, minute_reset_at: Time.current)

      result = described_class.call(query: "AAPL")

      expect(result).to be_failure
      expect(result.failure.first).to eq(:rate_limited)
    end
  end
end
