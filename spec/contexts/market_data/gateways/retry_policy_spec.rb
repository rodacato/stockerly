require "rails_helper"

RSpec.describe MarketData::Gateways::RetryPolicy do
  describe ".options" do
    it "caps the wait at what the environment allows" do
      options = described_class.options(max: 2, interval: 0.5, backoff_factor: 2)

      expect(options[:max_interval]).to eq(0)
    end

    it "leaves the gateway's own retry budget alone" do
      options = described_class.options(max: 2, interval: 0.5, backoff_factor: 2)

      expect(options).to include(max: 2, interval: 0.5, backoff_factor: 2)
    end

    it "declares no cap where the environment sets none" do
      allow(Rails.configuration.x).to receive(:gateway_retry_max_interval).and_return(nil)

      expect(described_class.options(max: 2, interval: 0.5)).not_to have_key(:max_interval)
    end
  end

  # A spec that only reads the options hash would never notice a cap that
  # stopped the retrying it was meant to leave alone.
  describe "a capped gateway against a failing provider" do
    it "still spends every attempt it declared" do
      stub_coingecko_server_error

      result = MarketData::Gateways::CoingeckoGateway.new(api_key: "test_key").fetch_price("BTC")

      expect(result).to be_failure
      expect(a_request(:get, %r{api\.coingecko\.com/api/v3/simple/price})).to have_been_made.times(3)
    end
  end
end
