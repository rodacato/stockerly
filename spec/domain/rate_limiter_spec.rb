require "rails_helper"

RSpec.describe RateLimiter do
  describe ".check!" do
    context "when provider does not exist" do
      it "returns Success(:allowed)" do
        result = described_class.check!("Unknown Provider")
        expect(result).to be_success
        expect(result.value!).to eq(:allowed)
      end
    end

    context "when provider has no rate limits configured" do
      let!(:integration) do
        create(:integration,
          provider_name: "Yahoo Finance",
          max_requests_per_minute: nil,
          daily_call_limit: 500,
          daily_api_calls: 0,
          calls_reset_at: Time.current)
      end

      it "returns Success and increments daily counter only" do
        result = described_class.check!("Yahoo Finance")
        expect(result).to be_success
        expect(integration.reload.daily_api_calls).to eq(1)
      end
    end

    context "when under both limits" do
      let!(:integration) do
        create(:integration,
          provider_name: "Polygon.io",
          max_requests_per_minute: 5,
          minute_calls: 2,
          minute_reset_at: Time.current,
          daily_call_limit: 500,
          daily_api_calls: 100,
          calls_reset_at: Time.current)
      end

      it "returns Success(:allowed)" do
        result = described_class.check!("Polygon.io")
        expect(result).to be_success
      end

      it "increments both minute and daily counters" do
        described_class.check!("Polygon.io")
        integration.reload
        expect(integration.minute_calls).to eq(3)
        expect(integration.daily_api_calls).to eq(101)
      end
    end

    context "when minute limit is exhausted" do
      let!(:integration) do
        create(:integration,
          provider_name: "Polygon.io",
          max_requests_per_minute: 5,
          minute_calls: 5,
          minute_reset_at: Time.current,
          daily_call_limit: 500,
          daily_api_calls: 100,
          calls_reset_at: Time.current)
      end

      it "returns Failure with rate_limited" do
        result = described_class.check!("Polygon.io")
        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
        expect(result.failure.last).to include("minute limit reached")
      end

      it "does not increment any counters" do
        described_class.check!("Polygon.io")
        integration.reload
        expect(integration.minute_calls).to eq(5)
        expect(integration.daily_api_calls).to eq(100)
      end
    end

    context "when daily limit is exhausted" do
      let!(:integration) do
        create(:integration,
          provider_name: "Alpha Vantage",
          max_requests_per_minute: 5,
          minute_calls: 0,
          minute_reset_at: Time.current,
          daily_call_limit: 25,
          daily_api_calls: 25,
          calls_reset_at: Time.current)
      end

      it "returns Failure with rate_limited" do
        result = described_class.check!("Alpha Vantage")
        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
        expect(result.failure.last).to include("daily limit reached")
      end
    end

    context "when minute window has expired" do
      let!(:integration) do
        create(:integration,
          provider_name: "CoinGecko",
          max_requests_per_minute: 30,
          minute_calls: 30,
          minute_reset_at: 2.minutes.ago,
          daily_call_limit: 10_000,
          daily_api_calls: 100,
          calls_reset_at: Time.current)
      end

      it "allows the request (expired window resets)" do
        result = described_class.check!("CoinGecko")
        expect(result).to be_success
      end
    end
  end
end
