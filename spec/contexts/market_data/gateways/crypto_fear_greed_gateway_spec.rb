require "rails_helper"

RSpec.describe MarketData::Gateways::CryptoFearGreedGateway do
  subject(:gateway) { described_class.new }

  describe "#fetch_index" do
    context "when API returns valid data" do
      before { stub_crypto_fear_greed(value: 25, classification: "Extreme Fear") }

      it "returns Success with parsed data" do
        result = gateway.fetch_index

        expect(result).to be_success
        data = result.value!
        expect(data[:value]).to eq(25)
        expect(data[:classification]).to eq("Extreme Fear")
        expect(data[:fetched_at]).to be_a(Time)
        expect(data[:component_data]).to eq({})
      end
    end

    context "when API returns 429" do
      before { stub_crypto_fear_greed_rate_limited }

      it "returns Failure with rate_limited" do
        result = gateway.fetch_index

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:rate_limited)
      end
    end

    context "when API returns 500" do
      before { stub_crypto_fear_greed_server_error }

      it "returns Failure with gateway_error" do
        result = gateway.fetch_index

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:gateway_error)
      end
    end

    context "when API returns malformed JSON" do
      before do
        stub_request(:get, %r{api\.alternative\.me/fng/})
          .to_return(status: 200, headers: { "Content-Type" => "application/json" }, body: { data: [] }.to_json)
      end

      it "returns Failure with parse_error" do
        result = gateway.fetch_index

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:parse_error)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{api\.alternative\.me/fng/})
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
