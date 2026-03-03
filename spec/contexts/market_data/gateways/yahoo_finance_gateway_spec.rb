require "rails_helper"

RSpec.describe MarketData::Gateways::YahooFinanceGateway do
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
        stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_price("GENIUSSACV.MX")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#fetch_index_quotes" do
    context "when Yahoo Finance returns valid index data" do
      before do
        stub_yahoo_index_quotes({
          "^GSPC" => { name: "S&P 500", value: 5214.33, change_percent: 0.42, is_open: true },
          "^IXIC" => { name: "NASDAQ Composite", value: 18322.40, change_percent: 1.15, is_open: true },
          "^MXX"  => { name: "IPC Mexico", value: 52180.50, change_percent: -0.30, is_open: false }
        })
      end

      it "returns Success with mapped index quotes" do
        result = gateway.fetch_index_quotes(%w[^GSPC ^IXIC ^MXX])

        expect(result).to be_success
        quotes = result.value!
        expect(quotes.size).to eq(3)
        expect(quotes.map { |q| q[:symbol] }).to contain_exactly("SPX", "NDX", "IPC")
      end

      it "maps Yahoo symbols to internal symbols" do
        result = gateway.fetch_index_quotes(%w[^GSPC ^IXIC ^MXX])
        spx = result.value!.find { |q| q[:symbol] == "SPX" }

        expect(spx[:name]).to eq("S&P 500")
        expect(spx[:value]).to eq(5214.33.to_d)
        expect(spx[:change_percent]).to be_within(0.01).of(0.42)
        expect(spx[:is_open]).to be true
      end
    end

    context "when no data returned" do
      before { stub_yahoo_index_quotes_empty }

      it "returns Failure with :not_found" do
        result = gateway.fetch_index_quotes(%w[^GSPC])

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{query2\.finance\.yahoo\.com/v8/finance/chart/})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_index_quotes(%w[^GSPC])

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
