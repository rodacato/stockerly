require "rails_helper"

RSpec.describe Administration::UseCases::Integrations::UpdateProvider do
  include ActiveJob::TestHelper

  let(:admin) { create(:user, :admin) }
  let!(:integration) { create(:integration, provider_name: "Alpaca", daily_call_limit: 500) }

  describe ".call" do
    context "with valid params" do
      it "updates the integration" do
        result = described_class.call(
          params: { id: integration.id, daily_call_limit: 1000 }
        )

        expect(result).to be_success
        expect(integration.reload.daily_call_limit).to eq(1000)
      end

      it "updates max_requests_per_minute" do
        result = described_class.call(
          params: { id: integration.id, max_requests_per_minute: 10 }
        )

        expect(result).to be_success
        expect(integration.reload.max_requests_per_minute).to eq(10)
      end

      it "publishes IntegrationUpdated event" do
        expect(EventBus).to receive(:publish).with(instance_of(Administration::Events::IntegrationUpdated))

        described_class.call(
          params: { id: integration.id, daily_call_limit: 1000 }
        )
      end
    end

    context "when a key is saved" do
      before { integration.update!(connection_status: :disconnected, api_key_encrypted: nil, last_sync_at: nil) }

      it "stores it as not yet verified and enqueues the probe" do
        expect {
          described_class.call(params: { id: integration.id, api_key_encrypted: "hola" })
        }.to have_enqueued_job(SyncIntegrationJob).with(integration.id)

        expect(integration.reload).to have_attributes(api_key_encrypted: "hola", connection_status: "syncing", last_sync_at: nil)
      end

      it "ends connected when the probe accepts it" do
        stub_alpaca_bars({ "AAPL" => [ alpaca_bar(date: 3.days.ago.to_date.to_s) ] })

        perform_enqueued_jobs { described_class.call(params: { id: integration.id, api_key_encrypted: "PKID:secret" }) }

        expect(integration.reload.connection_status).to eq("connected")
      end

      it "ends disconnected when the probe rejects it" do
        stub_alpaca_recent_denied

        perform_enqueued_jobs { described_class.call(params: { id: integration.id, api_key_encrypted: "hola" }) }

        expect(integration.reload.connection_status).to eq("disconnected")
      end

      it "ends disconnected when the gateway raises" do
        stub_request(:get, %r{data\.alpaca\.markets/}).to_raise(Errno::ECONNREFUSED)

        perform_enqueued_jobs { described_class.call(params: { id: integration.id, api_key_encrypted: "hola" }) }

        expect(integration.reload.connection_status).to eq("disconnected")
      end
    end

    context "when the key field is blank" do
      it "changes neither the stored key nor the status, and enqueues nothing" do
        integration.update!(api_key_encrypted: "old", connection_status: :connected)

        expect {
          described_class.call(params: { id: integration.id, api_key_encrypted: "", daily_call_limit: 600 })
        }.not_to have_enqueued_job(SyncIntegrationJob)

        expect(integration.reload).to have_attributes(api_key_encrypted: "old", connection_status: "connected", daily_call_limit: 600)
      end
    end

    context "with invalid params" do
      it "fails when daily_call_limit is not positive" do
        result = described_class.call(
          params: { id: integration.id, daily_call_limit: 0 }
        )

        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation)
      end

      it "fails when max_requests_per_minute is not positive" do
        result = described_class.call(
          params: { id: integration.id, max_requests_per_minute: -1 }
        )

        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation)
      end
    end

    context "when integration not found" do
      it "returns not_found failure" do
        result = described_class.call(
          params: { id: 999_999 }
        )

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end
  end
end
