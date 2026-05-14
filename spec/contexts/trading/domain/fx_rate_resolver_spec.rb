require "rails_helper"

RSpec.describe Trading::Domain::FxRateResolver do
  describe ".call" do
    context "when trade currency matches preferred currency" do
      it "returns BigDecimal(1) without any gateway call" do
        expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)

        result = described_class.call(trade_currency: "MXN", preferred_currency: "MXN")

        expect(result).to be_success
        expect(result.value!).to eq(BigDecimal(1))
      end

      it "normalizes currency case (mxn == MXN)" do
        expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)

        result = described_class.call(trade_currency: "mxn", preferred_currency: "MXN")

        expect(result).to be_success
        expect(result.value!).to eq(BigDecimal(1))
      end
    end

    context "when explicit override is provided" do
      it "returns the override regardless of DB or gateway state" do
        create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
        expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)

        result = described_class.call(
          trade_currency: "USD",
          preferred_currency: "MXN",
          override: BigDecimal("18.42")
        )

        expect(result).to be_success
        expect(result.value!).to eq(BigDecimal("18.42"))
      end
    end

    context "when forward FxRate exists in DB" do
      it "uses the latest row without calling the gateway" do
        create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)
        expect(MarketData::Gateways::FxRatesGateway).not_to receive(:new)

        result = described_class.call(trade_currency: "USD", preferred_currency: "MXN")

        expect(result).to be_success
        expect(result.value!).to eq(BigDecimal("17.5"))
      end
    end

    context "when no FxRate exists and gateway refresh succeeds" do
      let(:gateway) { instance_double(MarketData::Gateways::FxRatesGateway) }

      it "refreshes via the gateway then uses the new rate" do
        allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway)
        allow(gateway).to receive(:refresh_rates) do
          FxRate.create!(base_currency: "USD", quote_currency: "MXN", rate: 17.25, fetched_at: Time.current)
        end

        result = described_class.call(trade_currency: "USD", preferred_currency: "MXN")

        expect(result).to be_success
        expect(result.value!).to eq(BigDecimal("17.25"))
        expect(gateway).to have_received(:refresh_rates).with(base: "USD", targets: [ "MXN" ])
      end
    end

    context "when only an inverse rate exists" do
      let(:gateway) { instance_double(MarketData::Gateways::FxRatesGateway, refresh_rates: nil) }

      before { allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway) }

      it "inverts the reverse-direction rate" do
        create(:fx_rate, base_currency: "USD", quote_currency: "MXN", rate: 17.5)

        result = described_class.call(trade_currency: "MXN", preferred_currency: "USD")

        expect(result).to be_success
        expect(result.value!).to be_within(BigDecimal("0.0001")).of(BigDecimal(1) / BigDecimal("17.5"))
      end
    end

    context "when no rate is available anywhere" do
      let(:gateway) { instance_double(MarketData::Gateways::FxRatesGateway, refresh_rates: nil) }

      before { allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway) }

      it "returns Failure(:fx_rate_unavailable)" do
        result = described_class.call(trade_currency: "USD", preferred_currency: "MXN")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:fx_rate_unavailable)
        expect(result.failure[1]).to include("USD -> MXN")
      end
    end

    context "when the gateway raises an error" do
      let(:gateway) { instance_double(MarketData::Gateways::FxRatesGateway) }

      before do
        allow(MarketData::Gateways::FxRatesGateway).to receive(:new).and_return(gateway)
        allow(gateway).to receive(:refresh_rates).and_raise(StandardError, "API down")
      end

      it "falls back to inverse rate when available" do
        create(:fx_rate, base_currency: "MXN", quote_currency: "USD", rate: BigDecimal("0.06"))

        result = described_class.call(trade_currency: "USD", preferred_currency: "MXN")

        expect(result).to be_success
        expect(result.value!).to be_within(BigDecimal("0.01")).of(BigDecimal(1) / BigDecimal("0.06"))
      end

      it "fails cleanly when no fallback exists" do
        result = described_class.call(trade_currency: "USD", preferred_currency: "MXN")

        expect(result).to be_failure
        expect(result.failure.first).to eq(:fx_rate_unavailable)
      end
    end
  end
end
