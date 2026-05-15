require "rails_helper"

RSpec.describe MarketData::UseCases::EnsureFreshFxRate do
  describe ".call" do
    it "returns Success(rate) from cache without hitting the gateway" do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
      expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)

      result = described_class.call(base: "USD", target: "MXN")
      expect(result).to be_success
      expect(result.value!).to eq(BigDecimal("17.5"))
    end

    it "refreshes from the gateway on cache miss and retries the read" do
      gateway = instance_double(MarketData::Gateways::FxRatesGateway)
      allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway)
      expect(gateway).to receive(:refresh_rates).with(base: "USD", targets: [ "MXN" ]).and_invoke(
        ->(**_) { create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 18.4) }
      )

      result = described_class.call(base: "USD", target: "MXN")
      expect(result).to be_success
      expect(result.value!).to eq(BigDecimal("18.4"))
    end

    it "falls back to inverse direction when direct lookup stays empty after refresh" do
      gateway = instance_double(MarketData::Gateways::FxRatesGateway)
      allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway)
      # Refresh populates the inverse direction only — common when the
      # gateway speaks one direction natively.
      allow(gateway).to receive(:refresh_rates).and_invoke(
        ->(**_) { create(:fx_rate, base_currency: "MXN", quote_currency: "USD", rate: BigDecimal("0.054")) }
      )

      result = described_class.call(base: "USD", target: "MXN")
      expect(result).to be_success
      expect(result.value!).to be_within(BigDecimal("0.01")).of(BigDecimal(1) / BigDecimal("0.054"))
    end

    it "returns Failure(:fx_rate_unavailable) when both directions are missing" do
      gateway = instance_double(MarketData::Gateways::FxRatesGateway)
      allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway)
      allow(gateway).to receive(:refresh_rates) # no-op

      result = described_class.call(base: "USD", target: "MXN")
      expect(result).to be_failure
      expect(result.failure.first).to eq(:fx_rate_unavailable)
      expect(result.failure[1]).to include("USD -> MXN")
    end

    it "logs gateway errors but still returns Failure (no exception bubbling)" do
      gateway = instance_double(MarketData::Gateways::FxRatesGateway)
      allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway)
      allow(gateway).to receive(:refresh_rates).and_raise(Faraday::ConnectionFailed.new("timeout"))
      expect(Rails.logger).to receive(:error).with(/FX refresh failed for USD->MXN.*timeout/)

      result = described_class.call(base: "USD", target: "MXN")
      expect(result).to be_failure
      expect(result.failure.first).to eq(:fx_rate_unavailable)
    end

    it "upcases base/target inputs (so 'usd'/'mxn' work the same)" do
      create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
      result = described_class.call(base: "usd", target: "mxn")
      expect(result.value!).to eq(BigDecimal("17.5"))
    end
  end
end
