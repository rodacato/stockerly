require "rails_helper"

RSpec.describe MarketData::Gateways::FxRatesGateway do
  subject(:gateway) { described_class.new(api_key: "test_key") }

  describe "#refresh_rates" do
    context "when ExchangeRate API returns valid data" do
      before { stub_fx_rates }

      it "returns Success and upserts FxRate records" do
        expect {
          result = gateway.refresh_rates(base: "USD", targets: %w[EUR MXN GBP])
          expect(result).to be_success
          expect(result.value!).to eq(:rates_refreshed)
        }.to change(FxRate, :count).by(3)
      end

      it "updates existing rates via upsert" do
        create(:fx_rate, base_currency: "USD", quote_currency: "EUR", rate: 0.85)

        gateway.refresh_rates(base: "USD", targets: %w[EUR])

        expect(FxRate.find_by(base_currency: "USD", quote_currency: "EUR").rate.to_f).to eq(0.92)
      end

      it "skips targets not present in API response" do
        stub_fx_rates(rates: { "EUR" => 0.92 })

        expect {
          gateway.refresh_rates(base: "USD", targets: %w[EUR JPY])
        }.to change(FxRate, :count).by(1)
      end
    end

    context "when rate limited (429)" do
      before { stub_fx_rates_rate_limited }

      it "returns Failure with :rate_limited" do
        result = gateway.refresh_rates

        expect(result).to be_failure
        expect(result.failure.first).to eq(:rate_limited)
      end
    end

    context "when server error (500)" do
      before { stub_fx_rates_server_error }

      it "returns Failure with :gateway_error" do
        result = gateway.refresh_rates

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end

    context "when connection times out" do
      before do
        stub_request(:get, %r{v6\.exchangerate-api\.com/v6/.+/latest})
          .to_timeout
      end

      it "returns Failure with :gateway_error" do
        result = gateway.refresh_rates

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end

    context "when response is missing conversion_rates" do
      before do
        stub_request(:get, %r{v6\.exchangerate-api\.com/v6/.+/latest})
          .to_return(
            status: 200,
            headers: { "Content-Type" => "application/json" },
            body: { result: "error", "error-type": "invalid-key" }.to_json
          )
      end

      it "returns Failure with :gateway_error" do
        result = gateway.refresh_rates

        expect(result).to be_failure
        expect(result.failure.first).to eq(:gateway_error)
      end
    end
  end

  describe "API key resolution" do
    context "when Integration record exists with valid key" do
      before do
        integration = create(:integration, provider_name: "ExchangeRate", api_key_encrypted: "db_key")
        create(:api_key_pool, :default, integration: integration, api_key_encrypted: "db_key")
      end

      it "uses the database key" do
        expect { described_class.new }.not_to raise_error
      end
    end

    context "when no Integration record exists" do
      it "raises ApiKeyNotConfiguredError" do
        expect { described_class.new }.to raise_error(
          MarketData::Gateways::ApiKeyNotConfiguredError, /ExchangeRate/
        )
      end
    end

    context "when Integration exists but api_key_encrypted is nil" do
      before { create(:integration, :keyless, provider_name: "ExchangeRate") }

      it "raises ApiKeyNotConfiguredError" do
        expect { described_class.new }.to raise_error(
          MarketData::Gateways::ApiKeyNotConfiguredError
        )
      end
    end
  end
end
