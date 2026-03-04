require "rails_helper"

RSpec.describe MarketData::Gateways::PolygonGateway do
  subject(:gateway) { described_class.new(api_key: "test_key") }

  describe "#fetch_price" do
    context "when Polygon returns valid data" do
      before { stub_polygon_price("AAPL", close: 189.43, open: 185.00, volume: 58_200_000) }

      it "returns Success with parsed price data" do
        result = gateway.fetch_price("AAPL")

        expect(result).to be_success
        data = result.value!
        expect(data[:symbol]).to eq("AAPL")
        expect(data[:price]).to eq(189.43.to_d)
        expect(data[:volume]).to eq(58_200_000)
        expect(data[:change_percent]).to be_a(BigDecimal)
      end
    end

    context "when symbol has no results" do
      before { stub_polygon_not_found("FAKE") }

      it "returns Failure with :not_found" do
        result = gateway.fetch_price("FAKE")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when rate limited (429)" do
      before { stub_polygon_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_price("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when server error (500)" do
      before { stub_polygon_server_error }

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_price("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{api\.polygon\.io/v2/aggs/ticker/.+/prev})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_price("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#fetch_bulk_prices" do
    before do
      stub_polygon_price("AAPL", close: 189.43)
      stub_polygon_price("MSFT", close: 420.50)
    end

    it "returns Success with array of price data" do
      result = gateway.fetch_bulk_prices(%w[AAPL MSFT])

      expect(result).to be_success
      expect(result.value!.size).to eq(2)
      expect(result.value!.map { |d| d[:symbol] }).to contain_exactly("AAPL", "MSFT")
    end
  end

  describe "#fetch_historical" do
    context "when Polygon returns valid bars" do
      before { stub_polygon_historical("AAPL", days: 7) }

      it "returns Success with OHLCV data" do
        result = gateway.fetch_historical("AAPL", "2026-02-16", "2026-02-23")

        expect(result).to be_success
        bars = result.value!
        expect(bars.size).to eq(7)
        expect(bars.first).to include(:date, :open, :high, :low, :close, :volume)
        expect(bars.first[:close]).to be_a(BigDecimal)
      end
    end

    context "when no data returned" do
      before { stub_polygon_historical_empty("AAPL") }

      it "returns Failure with :not_found" do
        result = gateway.fetch_historical("AAPL", "2026-02-16", "2026-02-23")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{api\.polygon\.io/v2/aggs/ticker/.+/range/})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_historical("AAPL", "2026-02-16", "2026-02-23")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#fetch_news" do
    context "when Polygon returns articles" do
      before { stub_polygon_news(count: 3) }

      it "returns Success with parsed articles" do
        result = gateway.fetch_news

        expect(result).to be_success
        articles = result.value!
        expect(articles.size).to eq(3)
        expect(articles.first).to include(:title, :summary, :source, :url, :published_at, :related_ticker)
        expect(articles.first[:title]).to eq("Article 1")
        expect(articles.first[:source]).to eq("Bloomberg")
        expect(articles.first[:related_ticker]).to eq("AAPL")
      end
    end

    context "when no articles returned" do
      before { stub_polygon_news_empty }

      it "returns Success with empty array" do
        result = gateway.fetch_news

        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{api\.polygon\.io/v2/reference/news})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_news

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#fetch_earnings" do
    context "when Polygon returns earnings data" do
      before { stub_polygon_earnings("AAPL") }

      it "returns Success with parsed earnings" do
        result = gateway.fetch_earnings("AAPL")

        expect(result).to be_success
        events = result.value!
        expect(events.size).to eq(2)
        expect(events.first).to include(:report_date, :fiscal_quarter, :fiscal_year, :estimated_eps, :timing)
        expect(events.first[:fiscal_quarter]).to eq("Q1")
        expect(events.first[:estimated_eps]).to be_a(BigDecimal)
      end
    end

    context "when no earnings data returned" do
      before { stub_polygon_earnings_empty("AAPL") }

      it "returns Success with empty array" do
        result = gateway.fetch_earnings("AAPL")

        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end

    context "when rate limited (429)" do
      before { stub_polygon_earnings_rate_limited("AAPL") }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_earnings("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{api\.polygon\.io/vX/reference/tickers/.+/earnings})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_earnings("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "API key resolution" do
    context "when Integration record exists with valid key" do
      before { create(:integration, provider_name: "Polygon.io", api_key_encrypted: "db_key") }

      it "uses the database key" do
        expect { described_class.new }.not_to raise_error
      end
    end

    context "when no Integration record exists" do
      it "raises ApiKeyNotConfiguredError" do
        expect { described_class.new }.to raise_error(
          MarketData::Gateways::ApiKeyNotConfiguredError, /Polygon\.io/
        )
      end
    end

    context "when Integration exists but api_key_encrypted is nil" do
      before { create(:integration, :keyless, provider_name: "Polygon.io") }

      it "raises ApiKeyNotConfiguredError" do
        expect { described_class.new }.to raise_error(
          MarketData::Gateways::ApiKeyNotConfiguredError
        )
      end
    end
  end
end
