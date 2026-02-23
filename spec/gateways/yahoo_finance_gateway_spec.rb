require "rails_helper"

RSpec.describe YahooFinanceGateway do
  subject(:gateway) { described_class.new }

  describe "#fetch_price" do
    context "when Yahoo Finance returns valid data" do
      before { stub_yahoo_finance_price("GENIUSSACV.MX", price: 25.50, change_percent: 1.25, volume: 500_000) }

      it "returns Success with parsed price data" do
        result = gateway.fetch_price("GENIUSSACV.MX")

        expect(result).to be_success
        data = result.value!
        expect(data[:symbol]).to eq("GENIUSSACV.MX")
        expect(data[:price]).to eq(25.50.to_d)
        expect(data[:volume]).to eq(500_000)
        expect(data[:change_percent]).to be_a(BigDecimal)
      end
    end

    context "when symbol has no results" do
      before { stub_yahoo_finance_not_found("FAKE.MX") }

      it "returns Failure with :not_found" do
        result = gateway.fetch_price("FAKE.MX")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when rate limited (429)" do
      before { stub_yahoo_finance_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_price("GENIUSSACV.MX")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when server error (500)" do
      before { stub_yahoo_finance_server_error }

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_price("GENIUSSACV.MX")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{query1\.finance\.yahoo\.com/v8/finance/quote})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_price("GENIUSSACV.MX")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#fetch_bulk_prices" do
    before do
      stub_yahoo_finance_bulk({
        "GENIUSSACV.MX" => { price: 25.50, change_percent: 1.25, volume: 500_000 },
        "IVVPESO.MX" => { price: 48.30, change_percent: -0.50, volume: 200_000 }
      })
    end

    it "returns Success with array of price data" do
      result = gateway.fetch_bulk_prices(%w[GENIUSSACV.MX IVVPESO.MX])

      expect(result).to be_success
      expect(result.value!.size).to eq(2)
      expect(result.value!.map { |d| d[:symbol] }).to contain_exactly("GENIUSSACV.MX", "IVVPESO.MX")
    end
  end
end
