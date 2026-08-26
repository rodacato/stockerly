require "rails_helper"

RSpec.describe "Gateway RateLimiter integration" do
  describe "MarketData::Gateways::AlpacaGateway" do
    subject(:gateway) { MarketData::Gateways::AlpacaGateway.new(api_key: "PKID:secret") }

    let!(:integration) do
      create(:integration,
        provider_name: "Alpaca",
        max_requests_per_minute: 200,
        minute_calls: 200,
        minute_reset_at: Time.current,
        daily_call_limit: 50_000,
        daily_api_calls: 0,
        calls_reset_at: Time.current)
    end

    it "blocks fetch_daily_bars when minute limit is exhausted" do
      result = gateway.fetch_daily_bars(%w[AAPL], 7.days.ago.to_date, 2.days.ago.to_date)

      expect(result.failure.first).to eq(:rate_limited)
      expect(result.failure.last).to include("minute limit reached")
    end

    it "blocks fetch_news when minute limit is exhausted" do
      expect(gateway.fetch_news(ticker: "AAPL").failure.first).to eq(:rate_limited)
    end

    it "blocks fetch_dividends when minute limit is exhausted" do
      expect(gateway.fetch_dividends("AAPL").failure.first).to eq(:rate_limited)
    end
  end

  describe "MarketData::Gateways::CoingeckoGateway" do
    subject(:gateway) { MarketData::Gateways::CoingeckoGateway.new(api_key: "test_key") }

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

  describe "MarketData::Gateways::AlphaVantageGateway" do
    subject(:gateway) { MarketData::Gateways::AlphaVantageGateway.new(api_key: "test_key") }

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

  describe "MarketData::Gateways::FxRatesGateway" do
    subject(:gateway) { MarketData::Gateways::FxRatesGateway.new(api_key: "test_key") }

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
