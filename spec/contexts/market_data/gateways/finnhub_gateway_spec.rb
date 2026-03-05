require "rails_helper"

RSpec.describe MarketData::Gateways::FinnhubGateway do
  subject(:gateway) { described_class.new(api_key: "test_key") }

  describe "#fetch_price" do
    context "when Finnhub returns valid data" do
      before { stub_finnhub_quote("AAPL", current: 189.43, change_percent: 1.69) }

      it "returns Success with parsed price data" do
        result = gateway.fetch_price("AAPL")

        expect(result).to be_success
        data = result.value!
        expect(data[:symbol]).to eq("AAPL")
        expect(data[:price]).to eq(189.43.to_d)
        expect(data[:change_percent]).to eq(1.69.to_d)
        expect(data[:volume]).to be_nil
      end
    end

    context "when symbol has no results (c=0)" do
      before { stub_finnhub_quote_not_found("FAKE") }

      it "returns Failure with :not_found" do
        result = gateway.fetch_price("FAKE")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when rate limited (429)" do
      before { stub_finnhub_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_price("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when server error (500)" do
      before { stub_finnhub_server_error }

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_price("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{finnhub\.io/api/v1/quote})
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
      stub_finnhub_quote("AAPL", current: 189.43)
      stub_finnhub_quote("MSFT", current: 420.50)
    end

    it "returns Success with array of price data" do
      result = gateway.fetch_bulk_prices(%w[AAPL MSFT])

      expect(result).to be_success
      expect(result.value!.size).to eq(2)
      expect(result.value!.map { |d| d[:symbol] }).to contain_exactly("AAPL", "MSFT")
    end

    context "when one symbol fails" do
      before do
        stub_finnhub_quote("AAPL", current: 189.43)
        stub_finnhub_quote_not_found("FAKE")
      end

      it "returns Success with only successful results" do
        result = gateway.fetch_bulk_prices(%w[AAPL FAKE])

        expect(result).to be_success
        expect(result.value!.size).to eq(1)
        expect(result.value!.first[:symbol]).to eq("AAPL")
      end
    end
  end

  describe "#fetch_historical" do
    context "when Finnhub returns valid candles" do
      before { stub_finnhub_candles("AAPL", days: 7) }

      it "returns Success with OHLCV data" do
        result = gateway.fetch_historical("AAPL", "2026-02-16", "2026-02-23")

        expect(result).to be_success
        bars = result.value!
        expect(bars.size).to eq(7)
        expect(bars.first).to include(:date, :open, :high, :low, :close, :volume)
        expect(bars.first[:close]).to be_a(BigDecimal)
      end
    end

    context "when no data returned (status no_data)" do
      before { stub_finnhub_candles_empty("AAPL") }

      it "returns Failure with :not_found" do
        result = gateway.fetch_historical("AAPL", "2026-02-16", "2026-02-23")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end

    context "when rate limited (429)" do
      before { stub_finnhub_candles_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_historical("AAPL", "2026-02-16", "2026-02-23")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{finnhub\.io/api/v1/stock/candle})
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
    context "when Finnhub returns valid news" do
      before { stub_finnhub_news("AAPL", count: 3) }

      it "returns Success with parsed articles" do
        result = gateway.fetch_news(ticker: "AAPL")

        expect(result).to be_success
        articles = result.value!
        expect(articles.size).to eq(3)
        expect(articles.first).to include(:title, :summary, :source, :url, :image_url, :published_at, :related_ticker)
        expect(articles.first[:title]).to eq("Article 1 about AAPL")
        expect(articles.first[:source]).to eq("Reuters")
        expect(articles.first[:related_ticker]).to eq("AAPL")
      end
    end

    context "when no ticker provided" do
      it "returns Failure with :not_supported" do
        result = gateway.fetch_news

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_supported)
      end
    end

    context "when no articles found" do
      before { stub_finnhub_news_empty("AAPL") }

      it "returns Success with empty array" do
        result = gateway.fetch_news(ticker: "AAPL")

        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end

    context "when limit is applied" do
      before { stub_finnhub_news("AAPL", count: 10) }

      it "limits the number of articles returned" do
        result = gateway.fetch_news(ticker: "AAPL", limit: 2)

        expect(result).to be_success
        expect(result.value!.size).to eq(2)
      end
    end

    context "when rate limited (429)" do
      before { stub_finnhub_news_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_news(ticker: "AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{finnhub\.io/api/v1/company-news})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_news(ticker: "AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#fetch_earnings" do
    context "when Finnhub returns valid earnings" do
      before { stub_finnhub_earnings("AAPL", count: 2) }

      it "returns Success with parsed earnings events" do
        result = gateway.fetch_earnings("AAPL")

        expect(result).to be_success
        events = result.value!
        expect(events.size).to eq(2)
        expect(events.first).to include(:report_date, :fiscal_quarter, :fiscal_year, :estimated_eps, :actual_eps, :timing)
        expect(events.first[:actual_eps]).to eq(1.52.to_d)
        expect(events.first[:timing]).to eq(:before_market_open)
        expect(events.last[:timing]).to eq(:after_market_close)
      end
    end

    context "when no earnings found" do
      before { stub_finnhub_earnings_empty("AAPL") }

      it "returns Success with empty array" do
        result = gateway.fetch_earnings("AAPL")

        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end

    context "when rate limited (429)" do
      before { stub_finnhub_earnings_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.fetch_earnings("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{finnhub\.io/api/v1/calendar/earnings})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.fetch_earnings("AAPL")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "#search_tickers" do
    context "when Finnhub returns results" do
      before { stub_finnhub_search("apple", count: 2) }

      it "returns Success with parsed results" do
        result = gateway.search_tickers("apple")

        expect(result).to be_success
        tickers = result.value!
        expect(tickers.size).to eq(2)
        expect(tickers.first[:symbol]).to eq("AAPL")
        expect(tickers.first[:name]).to eq("APPLE INC")
        expect(tickers.first[:display_symbol]).to eq("AAPL")
        expect(tickers.first[:type]).to eq("Common Stock")
      end
    end

    context "when no results found" do
      before { stub_finnhub_search_empty("ZZZZZ") }

      it "returns Success with empty array" do
        result = gateway.search_tickers("ZZZZZ")

        expect(result).to be_success
        expect(result.value!).to be_empty
      end
    end

    context "when rate limited (429)" do
      before { stub_finnhub_search_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.search_tickers("apple")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{finnhub\.io/api/v1/search})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.search_tickers("apple")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "API key resolution" do
    context "when Integration record exists with valid key" do
      before do
        create(:integration, provider_name: "Finnhub", pool_key_value: "db_key")
      end

      it "uses the database key" do
        expect { described_class.new }.not_to raise_error
      end
    end

    context "when no Integration record exists" do
      it "raises ApiKeyNotConfiguredError" do
        expect { described_class.new }.to raise_error(
          MarketData::Gateways::ApiKeyNotConfiguredError, /Finnhub/
        )
      end
    end

    context "when Integration exists but api_key_encrypted is nil" do
      before { create(:integration, :keyless, provider_name: "Finnhub") }

      it "raises ApiKeyNotConfiguredError" do
        expect { described_class.new }.to raise_error(
          MarketData::Gateways::ApiKeyNotConfiguredError
        )
      end
    end
  end
end
