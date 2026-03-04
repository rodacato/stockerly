require "rails_helper"

RSpec.describe Administration::UseCases::Assets::SearchTicker do
  describe ".call" do
    context "with valid query" do
      before do
        stub_yahoo_ticker_search("AAPL", results: [
          { "symbol" => "AAPL", "longname" => "Apple Inc.", "quoteType" => "EQUITY",
            "exchange" => "NMS", "exchDisp" => "NASDAQ" },
          { "symbol" => "AAPL.MX", "shortname" => "Apple Inc.", "quoteType" => "EQUITY",
            "exchange" => "MEX", "exchDisp" => "Mexico" }
        ])
      end

      it "returns Success with mapped results" do
        result = described_class.call(query: "AAPL")

        expect(result).to be_success
        expect(result.value!.size).to eq(2)
      end

      it "maps EQUITY to stock asset_type" do
        result = described_class.call(query: "AAPL")
        first = result.value!.first

        expect(first[:symbol]).to eq("AAPL")
        expect(first[:name]).to eq("Apple Inc.")
        expect(first[:asset_type]).to eq("stock")
        expect(first[:exchange]).to eq("NASDAQ")
        expect(first[:country]).to eq("US")
      end

      it "maps MEX exchange to MX country" do
        result = described_class.call(query: "AAPL")
        mx = result.value!.last

        expect(mx[:symbol]).to eq("AAPL.MX")
        expect(mx[:country]).to eq("MX")
        expect(mx[:exchange]).to eq("BMV")
      end
    end

    context "with ETF and crypto results" do
      before do
        stub_yahoo_ticker_search("BTC", results: [
          { "symbol" => "BTC-USD", "longname" => "Bitcoin USD", "quoteType" => "CRYPTOCURRENCY",
            "exchange" => "CCC", "exchDisp" => "CCC" },
          { "symbol" => "IBIT", "longname" => "iShares Bitcoin Trust ETF", "quoteType" => "ETF",
            "exchange" => "PCX", "exchDisp" => "NYSEArca" }
        ])
      end

      it "maps CRYPTOCURRENCY to crypto and ETF to etf" do
        result = described_class.call(query: "BTC")

        crypto = result.value!.first
        expect(crypto[:asset_type]).to eq("crypto")
        expect(crypto[:exchange]).to eq("CRYPTO")
        expect(crypto[:country]).to be_nil

        etf = result.value!.last
        expect(etf[:asset_type]).to eq("etf")
        expect(etf[:exchange]).to eq("NYSE ARCA")
        expect(etf[:country]).to eq("US")
      end
    end

    context "with unknown exchange code" do
      before do
        stub_yahoo_ticker_search("TSM", results: [
          { "symbol" => "TSM", "longname" => "TSMC", "quoteType" => "EQUITY",
            "exchange" => "XYZ", "exchDisp" => "Unknown Exchange" }
        ])
      end

      it "falls back to exchDisp and nil country" do
        result = described_class.call(query: "TSM")
        first = result.value!.first

        expect(first[:exchange]).to eq("Unknown Exchange")
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
      before { stub_yahoo_ticker_search_error(status: 500) }

      it "propagates gateway Failure" do
        result = described_class.call(query: "AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end
end
