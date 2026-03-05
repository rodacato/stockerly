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

  describe "#fetch_news" do
    let(:news_data) { [{ title: "Article 1", summary: "Summary", source: "Reuters", url: "https://example.com", image_url: nil, published_at: Time.current, related_ticker: "AAPL" }] }

    context "when primary gateway succeeds" do
      it "returns the primary result" do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:respond_to?).with(:fetch_news).and_return(true)
        allow(primary_gateway).to receive(:fetch_news).and_return(Success(news_data))

        chain = described_class.new(gateways: [ primary_gateway ])
        result = chain.fetch_news(ticker: "AAPL")

        expect(result).to be_success
        expect(result.value!.first[:title]).to eq("Article 1")
      end
    end

    context "when primary fails and fallback succeeds" do
      let(:finnhub_gateway) { instance_double(MarketData::Gateways::FinnhubGateway) }

      it "returns fallback result" do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:respond_to?).with(:fetch_news).and_return(true)
        allow(primary_gateway).to receive(:fetch_news).and_return(Failure([ :gateway_error, "Error" ]))
        allow(finnhub_gateway).to receive_messages(class: MarketData::Gateways::FinnhubGateway)
        allow(finnhub_gateway).to receive(:respond_to?).with(:fetch_news).and_return(true)
        allow(finnhub_gateway).to receive(:fetch_news).and_return(Success(news_data))

        chain = described_class.new(gateways: [ primary_gateway, finnhub_gateway ])
        result = chain.fetch_news(ticker: "AAPL")

        expect(result).to be_success
      end
    end

    context "when all gateways fail" do
      it "returns Failure with :all_gateways_failed" do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:respond_to?).with(:fetch_news).and_return(true)
        allow(primary_gateway).to receive(:fetch_news).and_return(Failure([ :gateway_error, "Error" ]))

        chain = described_class.new(gateways: [ primary_gateway ])
        result = chain.fetch_news(ticker: "AAPL")

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:all_gateways_failed)
      end
    end

    context "when gateway does not support fetch_news" do
      it "skips the gateway" do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:respond_to?).with(:fetch_news).and_return(false)

        chain = described_class.new(gateways: [ primary_gateway ])
        result = chain.fetch_news(ticker: "AAPL")

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:all_gateways_failed)
      end
    end
  end

  describe "#fetch_earnings" do
    let(:earnings_data) { [{ report_date: Date.current, fiscal_quarter: 1, fiscal_year: 2026, estimated_eps: 1.45.to_d, actual_eps: 1.52.to_d, timing: :before_market_open }] }

    context "when primary gateway succeeds" do
      it "returns the primary result" do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:respond_to?).with(:fetch_earnings).and_return(true)
        allow(primary_gateway).to receive(:fetch_earnings).with("AAPL").and_return(Success(earnings_data))

        chain = described_class.new(gateways: [ primary_gateway ])
        result = chain.fetch_earnings("AAPL")

        expect(result).to be_success
        expect(result.value!.first[:actual_eps]).to eq(1.52.to_d)
      end
    end

    context "when primary fails and fallback succeeds" do
      let(:finnhub_gateway) { instance_double(MarketData::Gateways::FinnhubGateway) }

      it "returns fallback result" do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:respond_to?).with(:fetch_earnings).and_return(true)
        allow(primary_gateway).to receive(:fetch_earnings).and_return(Failure([ :rate_limited, "Limit" ]))
        allow(finnhub_gateway).to receive_messages(class: MarketData::Gateways::FinnhubGateway)
        allow(finnhub_gateway).to receive(:respond_to?).with(:fetch_earnings).and_return(true)
        allow(finnhub_gateway).to receive(:fetch_earnings).and_return(Success(earnings_data))

        chain = described_class.new(gateways: [ primary_gateway, finnhub_gateway ])
        result = chain.fetch_earnings("AAPL")

        expect(result).to be_success
      end
    end

    context "when all gateways fail" do
      it "returns Failure with :all_gateways_failed and ticker info" do
        allow(primary_gateway).to receive_messages(class: MarketData::Gateways::PolygonGateway)
        allow(primary_gateway).to receive(:respond_to?).with(:fetch_earnings).and_return(true)
        allow(primary_gateway).to receive(:fetch_earnings).and_return(Failure([ :gateway_error, "Error" ]))

        chain = described_class.new(gateways: [ primary_gateway ])
        result = chain.fetch_earnings("AAPL")

        expect(result).to be_failure
        expect(result.failure[0]).to eq(:all_gateways_failed)
        expect(result.failure[1]).to include("AAPL")
      end
    end
  end

  describe ".for_capability" do
    let(:test_gateway_class) { Class.new { def initialize(api_key: nil); end } }
    let(:test_gateway_class_2) { Class.new { def initialize(api_key: nil); end } }

    around do |example|
      saved = DataSourceRegistry.instance_variable_get(:@sources).dup
      DataSourceRegistry.clear!
      example.run
      DataSourceRegistry.instance_variable_set(:@sources, saved)
    end

    it "builds a chain from sources with the requested capability" do
      stub_const("TestGatewayA", test_gateway_class)
      stub_const("TestGatewayB", test_gateway_class_2)

      DataSourceRegistry.register(:source_a,
        name: "A", icon: "x", color: "blue", gateway_class: TestGatewayA,
        job_class: nil, job_args: [], test_symbol: nil,
        integration_name: "Provider A", circuit_breaker_key: "a",
        capabilities: %i[prices news])

      DataSourceRegistry.register(:source_b,
        name: "B", icon: "x", color: "red", gateway_class: TestGatewayB,
        job_class: nil, job_args: [], test_symbol: nil,
        integration_name: "Provider B", circuit_breaker_key: "b",
        capabilities: %i[news])

      chain = described_class.for_capability(:news)

      expect(chain).to be_a(described_class)
      expect(chain.instance_variable_get(:@gateways).size).to eq(2)
      expect(chain.instance_variable_get(:@gateways).map(&:class)).to eq([ TestGatewayA, TestGatewayB ])
    end

    it "deduplicates by gateway class" do
      stub_const("TestGatewayA", test_gateway_class)

      DataSourceRegistry.register(:source_a,
        name: "A", icon: "x", color: "blue", gateway_class: TestGatewayA,
        job_class: nil, job_args: [], test_symbol: nil,
        integration_name: "Provider A", circuit_breaker_key: "a",
        capabilities: %i[news])

      DataSourceRegistry.register(:source_b,
        name: "B", icon: "x", color: "red", gateway_class: TestGatewayA,
        job_class: nil, job_args: [], test_symbol: nil,
        integration_name: "Provider A", circuit_breaker_key: "b",
        capabilities: %i[news])

      chain = described_class.for_capability(:news)

      expect(chain.instance_variable_get(:@gateways).size).to eq(1)
    end

    it "skips gateways that raise ApiKeyNotConfiguredError" do
      error_class = Class.new(StandardError)
      stub_const("MarketData::Gateways::ApiKeyNotConfiguredError", error_class)

      failing_class = Class.new do
        define_method(:initialize) { |api_key: nil| raise error_class, "No key" }
      end
      stub_const("TestFailingGateway", failing_class)
      stub_const("TestGatewayA", test_gateway_class)

      DataSourceRegistry.register(:source_fail,
        name: "Fail", icon: "x", color: "red", gateway_class: TestFailingGateway,
        job_class: nil, job_args: [], test_symbol: nil,
        integration_name: "Failing", circuit_breaker_key: "f",
        capabilities: %i[news])

      DataSourceRegistry.register(:source_ok,
        name: "OK", icon: "x", color: "blue", gateway_class: TestGatewayA,
        job_class: nil, job_args: [], test_symbol: nil,
        integration_name: "OK", circuit_breaker_key: "o",
        capabilities: %i[news])

      chain = described_class.for_capability(:news)

      expect(chain.instance_variable_get(:@gateways).size).to eq(1)
      expect(chain.instance_variable_get(:@gateways).first).to be_a(TestGatewayA)
    end

    it "returns empty chain when no sources have the capability" do
      chain = described_class.for_capability(:nonexistent)

      expect(chain.instance_variable_get(:@gateways)).to be_empty
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
