require "rails_helper"

RSpec.describe YahooFinanceGateway, "#fetch_batch_quotes" do
  subject(:gateway) { described_class.new }

  let(:batch_response) do
    {
      quoteResponse: {
        result: [
          { symbol: "AAPL", regularMarketPrice: 189.43, regularMarketChangePercent: 1.25, regularMarketVolume: 50_000_000 },
          { symbol: "MSFT", regularMarketPrice: 420.10, regularMarketChangePercent: -0.50, regularMarketVolume: 30_000_000 }
        ]
      }
    }.to_json
  end

  context "when batch endpoint succeeds" do
    before do
      stub_request(:get, %r{query1\.finance\.yahoo\.com/v7/finance/quote})
        .with(query: hash_including("symbols" => "AAPL,MSFT"))
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: batch_response
        )
    end

    it "returns prices for all symbols in a single request" do
      result = gateway.fetch_batch_quotes(%w[AAPL MSFT])

      expect(result).to be_success
      data = result.value!
      expect(data.size).to eq(2)
      expect(data.first[:symbol]).to eq("AAPL")
      expect(data.first[:price]).to eq(189.43.to_d)
      expect(data.last[:symbol]).to eq("MSFT")
    end

    it "includes volume and change_percent" do
      result = gateway.fetch_batch_quotes(%w[AAPL MSFT])

      data = result.value!
      expect(data.first[:volume]).to eq(50_000_000)
      expect(data.first[:change_percent]).to eq(1.25)
    end
  end

  context "when batch endpoint fails" do
    before do
      stub_request(:get, %r{query1\.finance\.yahoo\.com/v7/finance/quote})
        .to_return(status: 500, body: "Server Error")

      # Fallback stubs for individual chart calls
      stub_yahoo_finance_price("AAPL", price: 189.43, change_percent: 1.25, volume: 50_000_000)
      stub_yahoo_finance_price("MSFT", price: 420.10, change_percent: -0.50, volume: 30_000_000)
    end

    it "falls back to individual chart calls" do
      result = gateway.fetch_batch_quotes(%w[AAPL MSFT])

      expect(result).to be_success
      data = result.value!
      expect(data.size).to eq(2)
    end
  end

  context "when batch endpoint returns rate limit" do
    before do
      stub_request(:get, %r{query1\.finance\.yahoo\.com/v7/finance/quote})
        .to_return(status: 429, body: "Rate limited")

      stub_yahoo_finance_price("AAPL", price: 189.43, change_percent: 1.25, volume: 50_000_000)
    end

    it "falls back to individual chart calls" do
      result = gateway.fetch_batch_quotes(%w[AAPL])

      expect(result).to be_success
      data = result.value!
      expect(data.first[:symbol]).to eq("AAPL")
    end
  end

  describe "#fetch_bulk_prices delegates to batch" do
    before do
      stub_request(:get, %r{query1\.finance\.yahoo\.com/v7/finance/quote})
        .with(query: hash_including("symbols" => "AAPL"))
        .to_return(
          status: 200,
          headers: { "Content-Type" => "application/json" },
          body: { quoteResponse: { result: [ { symbol: "AAPL", regularMarketPrice: 189.43, regularMarketChangePercent: 1.0, regularMarketVolume: 1000 } ] } }.to_json
        )
    end

    it "uses batch endpoint via fetch_bulk_prices" do
      result = gateway.fetch_bulk_prices(%w[AAPL])

      expect(result).to be_success
      expect(result.value!.first[:symbol]).to eq("AAPL")
    end
  end
end
