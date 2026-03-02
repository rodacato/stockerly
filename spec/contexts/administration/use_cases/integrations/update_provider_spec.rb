require "rails_helper"

RSpec.describe Administration::Integrations::UpdateProvider do
  let(:admin) { create(:user, :admin) }
  let!(:integration) { create(:integration, provider_name: "Polygon.io", daily_call_limit: 500) }

  describe ".call" do
    context "with valid params" do
      it "updates the integration" do
        result = described_class.call(
          admin: admin,
          params: { id: integration.id, daily_call_limit: 1000 }
        )

        expect(result).to be_success
        expect(integration.reload.daily_call_limit).to eq(1000)
      end

      it "updates max_requests_per_minute" do
        result = described_class.call(
          admin: admin,
          params: { id: integration.id, max_requests_per_minute: 10 }
        )

        expect(result).to be_success
        expect(integration.reload.max_requests_per_minute).to eq(10)
      end

      it "publishes IntegrationUpdated event" do
        expect(EventBus).to receive(:publish).with(instance_of(Administration::IntegrationUpdated))

        described_class.call(
          admin: admin,
          params: { id: integration.id, daily_call_limit: 1000 }
        )
      end
    end

    context "with invalid params" do
      it "fails when daily_call_limit is not positive" do
        result = described_class.call(
          admin: admin,
          params: { id: integration.id, daily_call_limit: 0 }
        )

        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation)
      end

      it "fails when max_requests_per_minute is not positive" do
        result = described_class.call(
          admin: admin,
          params: { id: integration.id, max_requests_per_minute: -1 }
        )

        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation)
      end
    end

    context "when integration not found" do
      it "returns not_found failure" do
        result = described_class.call(
          admin: admin,
          params: { id: 999_999 }
        )

        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end
  end
end
