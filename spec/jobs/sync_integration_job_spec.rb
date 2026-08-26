require "rails_helper"

RSpec.describe SyncIntegrationJob, type: :job do
  describe "#perform" do
    context "with an integration fronting several sources" do
      let!(:integration) { create(:integration, :keyless, provider_name: "Yahoo Finance") }

      it "checks the source marked for it, not whichever registered first" do
        allow(PythonRunner).to receive(:call).and_return(
          Dry::Monads::Success({ "price" => 1234.5, "currency" => "MXN" })
        )

        described_class.perform_now(integration.id)

        expect(PythonRunner).to have_received(:call)
        expect(integration.reload.connection_status).to eq("connected")
      end
    end

    context "with a source that takes no test symbol" do
      let!(:integration) { create(:integration, :keyless, provider_name: "Alternative.me") }

      it "still calls the gateway rather than reporting connected on faith" do
        gateway = instance_double(MarketData::Gateways::CryptoFearGreedGateway)
        allow(MarketData::Gateways::CryptoFearGreedGateway).to receive(:new).and_return(gateway)
        allow(gateway).to receive(:fetch_index).and_return(Dry::Monads::Success({ value: 25 }))

        described_class.perform_now(integration.id)

        expect(gateway).to have_received(:fetch_index).with(no_args)
        expect(integration.reload.connection_status).to eq("connected")
      end

      it "reports disconnected when that call fails" do
        gateway = instance_double(MarketData::Gateways::CryptoFearGreedGateway)
        allow(MarketData::Gateways::CryptoFearGreedGateway).to receive(:new).and_return(gateway)
        allow(gateway).to receive(:fetch_index)
          .and_return(Dry::Monads::Failure([ :gateway_error, "unreachable" ]))

        described_class.perform_now(integration.id)

        expect(integration.reload.connection_status).to eq("disconnected")
      end
    end

    context "with a keyed integration" do
      let!(:integration) do
        create(:integration, provider_name: "Alpaca", connection_status: :connected, api_key_encrypted: "PKID:secret")
      end

      context "when connectivity test succeeds" do
        before { stub_alpaca_bars({ "AAPL" => [ alpaca_bar(date: 3.days.ago.to_date.to_s) ] }) }

        it "sets status to connected and updates last_sync_at" do
          described_class.perform_now(integration.id)

          integration.reload
          expect(integration.connection_status).to eq("connected")
          expect(integration.last_sync_at).to be_present
        end

        it "creates a success SystemLog" do
          expect {
            described_class.perform_now(integration.id)
          }.to change(SystemLog, :count).by(1)

          expect(SystemLog.last.severity).to eq("success")
        end
      end

      context "when connectivity test fails" do
        before { stub_alpaca_recent_denied }

        it "sets status to disconnected" do
          described_class.perform_now(integration.id)

          integration.reload
          expect(integration.connection_status).to eq("disconnected")
        end

        it "creates an error SystemLog" do
          described_class.perform_now(integration.id)

          expect(SystemLog.last.severity).to eq("error")
        end
      end
    end

    context "with Alpha Vantage integration (fundamentals gateway)" do
      let!(:integration) do
        create(:integration, provider_name: "Alpha Vantage", connection_status: :connected, api_key_encrypted: "test_key")
      end

      context "when connectivity test succeeds" do
        before { stub_alpha_vantage_overview("AAPL") }

        it "uses fetch_overview instead of fetch_price" do
          described_class.perform_now(integration.id)

          integration.reload
          expect(integration.connection_status).to eq("connected")
          expect(integration.last_sync_at).to be_present
        end
      end

      context "when connectivity test fails" do
        before { stub_alpha_vantage_server_error }

        it "sets status to disconnected" do
          described_class.perform_now(integration.id)

          integration.reload
          expect(integration.connection_status).to eq("disconnected")
        end
      end
    end

    context "when integration requires API key but has none" do
      let!(:unconfigured) { create(:integration, provider_name: "Alpha Vantage", requires_api_key: true, api_key_encrypted: nil) }

      it "sets status to disconnected" do
        described_class.perform_now(unconfigured.id)

        unconfigured.reload
        expect(unconfigured.connection_status).to eq("disconnected")
      end

      it "creates an error SystemLog" do
        described_class.perform_now(unconfigured.id)

        expect(SystemLog.last.severity).to eq("error")
        expect(SystemLog.last.error_message).to include("API key required")
      end
    end

    context "when integration does not exist" do
      it "does nothing" do
        expect {
          described_class.perform_now(-1)
        }.not_to change(SystemLog, :count)
      end
    end
  end
end
