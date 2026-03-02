require "rails_helper"

RSpec.describe MarketData::FmpGateway do
  subject(:gateway) { described_class.new(api_key: "test_key") }

  before do
    allow(RateLimiter).to receive(:check!).and_return(Dry::Monads::Success())
  end

  describe "#fetch_dividends" do
    context "when FMP returns valid dividend data" do
      before do
        stub_request(:get, %r{financialmodelingprep\.com/api/v3/historical-price-full/stock_dividend/AAPL})
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: {
              symbol: "AAPL",
              historical: [
                { date: "2026-02-14", paymentDate: "2026-02-21", dividend: 0.25 },
                { date: "2025-11-08", paymentDate: "2025-11-15", dividend: 0.24 }
              ]
            }.to_json
          )
      end

      it "returns Success with parsed dividend data" do
        result = gateway.fetch_dividends("AAPL")

        expect(result).to be_success
        dividends = result.value!
        expect(dividends.size).to eq(2)
        expect(dividends.first[:ex_date]).to eq(Date.new(2026, 2, 14))
        expect(dividends.first[:pay_date]).to eq(Date.new(2026, 2, 21))
        expect(dividends.first[:amount_per_share]).to eq(0.25.to_d)
        expect(dividends.first[:currency]).to eq("USD")
      end
    end

    context "when FMP returns empty historical" do
      before do
        stub_request(:get, %r{financialmodelingprep\.com/api/v3/historical-price-full/stock_dividend/})
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: { symbol: "NEWCO", historical: [] }.to_json
          )
      end

      it "returns Success with empty array" do
        result = gateway.fetch_dividends("NEWCO")
        expect(result).to be_success
        expect(result.value!).to eq([])
      end
    end

    context "when rate limited" do
      before do
        allow(RateLimiter).to receive(:check!)
          .and_return(Dry::Monads::Failure([ :rate_limited, "FMP daily limit reached" ]))
      end

      it "returns Failure without making HTTP request" do
        result = gateway.fetch_dividends("AAPL")
        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end
  end

  describe "#fetch_splits" do
    context "when FMP returns valid split data" do
      before do
        stub_request(:get, %r{financialmodelingprep\.com/api/v3/historical-price-full/stock_split/AAPL})
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: {
              symbol: "AAPL",
              historical: [
                { date: "2020-08-31", numerator: 4, denominator: 1 },
                { date: "2014-06-09", numerator: 7, denominator: 1 }
              ]
            }.to_json
          )
      end

      it "returns Success with parsed split data" do
        result = gateway.fetch_splits("AAPL")

        expect(result).to be_success
        splits = result.value!
        expect(splits.size).to eq(2)
        expect(splits.first[:date]).to eq(Date.new(2020, 8, 31))
        expect(splits.first[:numerator]).to eq(4)
        expect(splits.first[:denominator]).to eq(1)
      end
    end

    context "when FMP returns 429" do
      before do
        stub_request(:get, %r{financialmodelingprep\.com/api/v3/historical-price-full/stock_split/})
          .to_return(status: 429, body: "Rate limit exceeded")
      end

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_splits("AAPL")
        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when FMP returns server error" do
      before do
        stub_request(:get, %r{financialmodelingprep\.com/api/v3/historical-price-full/stock_split/})
          .to_return(status: 500, body: "Internal Server Error")
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_splits("AAPL")
        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end
end
