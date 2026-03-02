require "rails_helper"

RSpec.describe "Gateway RateLimiter integration" do
  describe "MarketData::PolygonGateway" do
    subject(:gateway) { MarketData::PolygonGateway.new(api_key: "test_key") }

    let!(:integration) do
      create(:integration,
        provider_name: "Polygon.io",
        max_requests_per_minute: 5,
        minute_calls: 5,
        minute_reset_at: Time.current,
        daily_call_limit: 500,
        daily_api_calls: 0,
        calls_reset_at: Time.current)
    end

    it "blocks fetch_price when minute limit is exhausted" do
      result = gateway.fetch_price("AAPL")
      expect(result).to be_failure
      expect(result.failure.first).to eq(:rate_limited)
      expect(result.failure.last).to include("minute limit reached")
    end

    it "blocks fetch_news when minute limit is exhausted" do
      result = gateway.fetch_news(ticker: "AAPL")
      expect(result).to be_failure
      expect(result.failure.first).to eq(:rate_limited)
    end

    it "blocks fetch_grouped_daily when minute limit is exhausted" do
      result = gateway.fetch_grouped_daily
      expect(result).to be_failure
      expect(result.failure.first).to eq(:rate_limited)
    end
  end

  describe "MarketData::CoingeckoGateway" do
    subject(:gateway) { MarketData::CoingeckoGateway.new(api_key: "test_key") }

    let!(:integration) do
      create(:integration,
        provider_name: "CoinGecko",
        max_requests_per_minute: 30,
        minute_calls: 30,
        minute_reset_at: Time.current,
        daily_call_limit: 10_000,
        daily_api_calls: 0,
        calls_reset_at: Time.current)
    end

    it "blocks fetch_bulk_prices when minute limit is exhausted" do
      result = gateway.fetch_bulk_prices(%w[BTC])
      expect(result).to be_failure
      expect(result.failure.first).to eq(:rate_limited)
    end

    it "blocks fetch_market_data when minute limit is exhausted" do
      result = gateway.fetch_market_data(%w[BTC])
      expect(result).to be_failure
      expect(result.failure.first).to eq(:rate_limited)
    end
  end

  describe "MarketData::AlphaVantageGateway" do
    subject(:gateway) { MarketData::AlphaVantageGateway.new(api_key: "test_key") }

    let!(:integration) do
      create(:integration,
        provider_name: "Alpha Vantage",
        max_requests_per_minute: 5,
        daily_call_limit: 25,
        daily_api_calls: 25,
        calls_reset_at: Time.current)
    end

    it "blocks fetch_overview when daily limit is exhausted" do
      result = gateway.fetch_overview("AAPL")
      expect(result).to be_failure
      expect(result.failure.first).to eq(:rate_limited)
      expect(result.failure.last).to include("daily limit reached")
    end

    it "blocks fetch_income_statement when daily limit is exhausted" do
      result = gateway.fetch_income_statement("AAPL")
      expect(result).to be_failure
      expect(result.failure.first).to eq(:rate_limited)
    end
  end

  describe "MarketData::FxRatesGateway" do
    subject(:gateway) { MarketData::FxRatesGateway.new(api_key: "test_key") }

    let!(:integration) do
      create(:integration,
        provider_name: "ExchangeRate",
        daily_call_limit: 50,
        daily_api_calls: 50,
        calls_reset_at: Time.current)
    end

    it "blocks refresh_rates when daily limit is exhausted" do
      result = gateway.refresh_rates
      expect(result).to be_failure
      expect(result.failure.first).to eq(:rate_limited)
    end
  end
end
