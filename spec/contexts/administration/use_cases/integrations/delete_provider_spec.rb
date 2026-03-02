require "rails_helper"

RSpec.describe Administration::Integrations::DeleteProvider do
  let(:admin) { create(:user, :admin) }
  let!(:integration) { create(:integration, provider_name: "Test Provider") }

  describe ".call" do
    context "with valid params" do
      it "destroys the integration" do
        expect {
          described_class.call(admin: admin, params: { id: integration.id })
        }.to change(Integration, :count).by(-1)
      end

      it "returns Success(:deleted)" do
        result = described_class.call(admin: admin, params: { id: integration.id })
        expect(result).to be_success
        expect(result.value!).to eq(:deleted)
      end

      it "publishes IntegrationDeleted event" do
        expect(EventBus).to receive(:publish).with(instance_of(Administration::IntegrationDeleted))
        described_class.call(admin: admin, params: { id: integration.id })
      end

      it "cascades deletion to pool keys" do
        create(:api_key_pool, integration: integration)
        create(:api_key_pool, integration: integration)

        expect {
          described_class.call(admin: admin, params: { id: integration.id })
        }.to change(ApiKeyPool, :count).by(-2)
      end
    end

    context "when integration not found" do
      it "returns not_found failure" do
        result = described_class.call(admin: admin, params: { id: 999_999 })
        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end
  end
end
