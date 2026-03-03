require "rails_helper"

RSpec.describe GatewayChain do
  include Dry::Monads[:result]

  let(:success_data) { { symbol: "AAPL", price: 189.43.to_d, change_percent: 2.4, volume: 58_000_000 } }
  let(:primary_gateway) { instance_double(MarketData::Gateways::PolygonGateway) }
  let(:fallback_gateway) { instance_double(MarketData::Gateways::YahooFinanceGateway) }

  describe "#fetch_price" do
    context "when primary gateway succeeds" do
      it "returns the primary result with data_source" do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:fetch_price).with("AAPL").and_return(Success(success_data.dup))

        chain = described_class.new(gateways: [ primary_gateway, fallback_gateway ])
        result = chain.fetch_price("AAPL")

        expect(result).to be_success
        expect(result.value![:price]).to eq(189.43.to_d)
        expect(result.value![:data_source]).to eq("MarketData::Gateways::PolygonGateway")
      end

      it "does not call the fallback gateway" do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:fetch_price).and_return(Success(success_data.dup))
        allow(fallback_gateway).to receive_messages(class: MarketData::Gateways::YahooFinanceGateway)

        chain = described_class.new(gateways: [ primary_gateway, fallback_gateway ])
        chain.fetch_price("AAPL")

        expect(fallback_gateway).not_to have_received(:fetch_price) if fallback_gateway.respond_to?(:fetch_price)
      end
    end

    context "when primary gateway fails" do
      before do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:fetch_price).and_return(Failure([ :gateway_error, "Server error" ]))
        allow(fallback_gateway).to receive_messages(class: MarketData::Gateways::YahooFinanceGateway)
        allow(fallback_gateway).to receive(:fetch_price).and_return(Success(success_data.dup))
      end

      it "falls back to the next gateway" do
        chain = described_class.new(gateways: [ primary_gateway, fallback_gateway ])
        result = chain.fetch_price("AAPL")

        expect(result).to be_success
        expect(result.value![:data_source]).to eq("MarketData::Gateways::YahooFinanceGateway")
      end
    end

    context "when all gateways fail" do
      before do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:fetch_price).and_return(Failure([ :gateway_error, "Error 1" ]))
        allow(fallback_gateway).to receive_messages(class: MarketData::Gateways::YahooFinanceGateway)
        allow(fallback_gateway).to receive(:fetch_price).and_return(Failure([ :gateway_error, "Error 2" ]))
      end

      it "returns Failure with :all_gateways_failed" do
        chain = described_class.new(gateways: [ primary_gateway, fallback_gateway ])
        result = chain.fetch_price("AAPL")

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:all_gateways_failed)
        expect(result.failure[2]).to contain_exactly("MarketData::Gateways::PolygonGateway", "MarketData::Gateways::YahooFinanceGateway")
      end
    end

    context "with circuit breakers" do
      let(:breaker) { CircuitBreaker.new(name: "test", threshold: 1, timeout: 60) }

      it "skips gateway with open circuit breaker" do
        # Open the breaker
        breaker.call { Failure([ :gateway_error, "fail" ]) }
        expect(breaker.state).to eq(:open)

        allow(fallback_gateway).to receive_messages(class: MarketData::Gateways::YahooFinanceGateway)
        allow(fallback_gateway).to receive(:fetch_price).and_return(Success(success_data.dup))
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)

        chain = described_class.new(
          gateways: [ primary_gateway, fallback_gateway ],
          circuit_breakers: { "MarketData::Gateways::PolygonGateway" => breaker }
        )

        result = chain.fetch_price("AAPL")

        expect(result).to be_success
        expect(result.value![:data_source]).to eq("MarketData::Gateways::YahooFinanceGateway")
      end
    end

    context "with a single gateway" do
      it "returns the result directly" do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:fetch_price).and_return(Success(success_data.dup))

        chain = described_class.new(gateways: [ primary_gateway ])
        result = chain.fetch_price("AAPL")

        expect(result).to be_success
      end
    end
  end

  describe "#fetch_overview" do
    let(:overview_data) { { symbol: "AAPL", name: "Apple Inc.", eps: 6.42.to_d, market_cap: 3_100_000_000_000.to_d } }
    let(:av_gateway) { instance_double(MarketData::Gateways::AlphaVantageGateway) }
    let(:fmp_gateway) { instance_double(MarketData::Gateways::FmpGateway) }

    before do
      allow(av_gateway).to receive_messages(class: MarketData::Gateways::AlphaVantageGateway)
      allow(fmp_gateway).to receive_messages(class: MarketData::Gateways::FmpGateway)
    end

    context "when primary gateway succeeds" do
      it "returns the result with data_source" do
        allow(av_gateway).to receive(:respond_to?).with(:fetch_overview).and_return(true)
        allow(av_gateway).to receive(:fetch_overview).and_return(Success(overview_data.dup))
        allow(fmp_gateway).to receive(:respond_to?).with(:fetch_overview).and_return(true)

        chain = described_class.new(gateways: [ av_gateway, fmp_gateway ])
        result = chain.fetch_overview("AAPL")

        expect(result).to be_success
        expect(result.value![:data_source]).to eq("MarketData::Gateways::AlphaVantageGateway")
      end
    end

    context "when primary fails and fallback succeeds" do
      it "returns fallback result with correct data_source" do
        allow(av_gateway).to receive(:respond_to?).with(:fetch_overview).and_return(true)
        allow(av_gateway).to receive(:fetch_overview).and_return(Failure([ :rate_limited, "Rate limited" ]))
        allow(fmp_gateway).to receive(:respond_to?).with(:fetch_overview).and_return(true)
        allow(fmp_gateway).to receive(:fetch_overview).and_return(Success(overview_data.dup))

        chain = described_class.new(gateways: [ av_gateway, fmp_gateway ])
        result = chain.fetch_overview("AAPL")

        expect(result).to be_success
        expect(result.value![:data_source]).to eq("MarketData::Gateways::FmpGateway")
      end
    end
  end
end
