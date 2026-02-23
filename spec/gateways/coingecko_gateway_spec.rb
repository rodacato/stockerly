require "rails_helper"

RSpec.describe CoingeckoGateway do
  subject(:gateway) { described_class.new(api_key: "test_key") }

  describe "#fetch_price" do
    context "when CoinGecko returns valid data" do
      before { stub_coingecko_prices }

      it "returns Success with parsed price data" do
        result = gateway.fetch_price("BTC")

        expect(result).to be_success
        data = result.value!
        expect(data[:symbol]).to eq("BTC")
        expect(data[:price]).to eq(64_231.0.to_d)
        expect(data[:change_percent]).to be_a(BigDecimal)
        expect(data[:market_cap]).to be_a(BigDecimal)
      end
    end

    context "when symbol is unknown" do
      it "returns Failure with :not_found" do
        result = gateway.fetch_price("UNKNOWN_COIN")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when rate limited (429)" do
      before { stub_coingecko_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_price("BTC")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when server error (500)" do
      before { stub_coingecko_server_error }

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_price("BTC")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{api\.coingecko\.com/api/v3/simple/price})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_price("BTC")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#fetch_bulk_prices" do
    context "when CoinGecko returns data for multiple coins" do
      before { stub_coingecko_prices }

      it "returns Success with array of price data" do
        result = gateway.fetch_bulk_prices(%w[BTC ETH])

        expect(result).to be_success
        data = result.value!
        expect(data.size).to eq(2)
        expect(data.map { |d| d[:symbol] }).to contain_exactly("BTC", "ETH")
      end
    end

    context "when no symbols are recognized" do
      it "returns Success with empty array" do
        result = gateway.fetch_bulk_prices(%w[FAKE1 FAKE2])

        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end
  end

  describe "#fetch_historical" do
    context "when CoinGecko returns valid market chart" do
      before { stub_coingecko_historical(coin_id: "bitcoin", days: 7) }

      it "returns Success with daily price data" do
        result = gateway.fetch_historical("BTC", days: 7)

        expect(result).to be_success
        bars = result.value!
        expect(bars.size).to eq(7)
        expect(bars.first).to include(:date, :close)
        expect(bars.first[:close]).to be_a(BigDecimal)
      end
    end

    context "when symbol is unknown" do
      it "returns Failure with :not_found" do
        result = gateway.fetch_historical("UNKNOWN_COIN")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when API returns empty data" do
      before { stub_coingecko_historical_empty }

      it "returns Failure with :parse_error" do
        result = gateway.fetch_historical("BTC")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:parse_error)
      end
    end
  end
end
