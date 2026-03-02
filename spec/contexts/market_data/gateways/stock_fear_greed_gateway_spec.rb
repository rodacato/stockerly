require "rails_helper"

RSpec.describe MarketData::StockFearGreedGateway do
  subject(:gateway) { described_class.new }

  describe "#fetch_index" do
    context "when API returns valid data" do
      before { stub_stock_fear_greed(score: 62, rating: "Greed") }

      it "returns Success with parsed data" do
        result = gateway.fetch_index

        expect(result).to be_success
        data = result.value!
        expect(data[:value]).to eq(62)
        expect(data[:classification]).to eq("Greed")
        expect(data[:fetched_at]).to be_a(Time)
      end

      it "includes component data with sub-indicators" do
        result = gateway.fetch_index

        components = result.value![:component_data]
        expect(components).to have_key("market_momentum_sp500")
        expect(components).to have_key("market_volatility_vix")
        expect(components["market_momentum_sp500"][:score]).to eq(71.2)
        expect(components["market_momentum_sp500"][:rating]).to eq("Greed")
      end
    end

    context "when API returns 429" do
      before { stub_stock_fear_greed_rate_limited }

      it "returns Failure with rate_limited" do
        result = gateway.fetch_index

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:rate_limited)
      end
    end

    context "when API returns 500" do
      before { stub_stock_fear_greed_server_error }

      it "returns Failure with gateway_error" do
        result = gateway.fetch_index

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:gateway_error)
      end
    end

    context "when API returns empty response" do
      before do
        stub_request(:get, %r{production\.dataviz\.cnn\.io/index/fearandgreed/graphdata/})
          .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: {}.to_json)
      end

      it "returns Failure with parse_error" do
        result = gateway.fetch_index

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:parse_error)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{production\.dataviz\.cnn\.io/index/fearandgreed/graphdata/})
          .to_timeout
      end

      it "returns Failure with gateway_error" do
        result = gateway.fetch_index

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:gateway_error)
      end
    end
  end
end
