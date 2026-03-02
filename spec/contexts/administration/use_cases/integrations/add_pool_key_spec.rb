require "rails_helper"

RSpec.describe Administration::Integrations::AddPoolKey do
  let(:admin) { create(:user, :admin) }
  let!(:integration) { create(:integration, provider_name: "Polygon.io") }

  describe ".call" do
    context "with valid params" do
      let(:params) do
        { integration_id: integration.id, name: "Production Key", api_key_encrypted: "pk_prod_abc123" }
      end

      it "creates a new pool key" do
        expect {
          described_class.call(admin: admin, params: params)
        }.to change(ApiKeyPool, :count).by(1)
      end

      it "returns Success with pool key" do
        result = described_class.call(admin: admin, params: params)
        expect(result).to be_success
        expect(result.value!.name).to eq("Production Key")
        expect(result.value!.integration).to eq(integration)
      end

      it "publishes PoolKeyAdded event" do
        expect(EventBus).to receive(:publish).with(instance_of(Administration::PoolKeyAdded))
        described_class.call(admin: admin, params: params)
      end
    end

    context "with missing api key" do
      it "returns validation failure" do
        result = described_class.call(
          admin: admin,
          params: { integration_id: integration.id, name: "Key", api_key_encrypted: "" }
        )
        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation)
      end
    end

    context "with missing name" do
      it "returns validation failure" do
        result = described_class.call(
          admin: admin,
          params: { integration_id: integration.id, name: "", api_key_encrypted: "key123" }
        )
        expect(result).to be_failure
        expect(result.failure.first).to eq(:validation)
      end
    end

    context "when integration not found" do
      it "returns not_found failure" do
        result = described_class.call(
          admin: admin,
          params: { integration_id: 999_999, name: "Key", api_key_encrypted: "key123" }
        )
        expect(result).to be_failure
        expect(result.failure.first).to eq(:not_found)
      end
    end
  end
end
