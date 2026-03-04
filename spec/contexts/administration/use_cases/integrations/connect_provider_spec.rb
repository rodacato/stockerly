require "rails_helper"

RSpec.describe Administration::UseCases::Integrations::ConnectProvider do
  describe ".call" do
    let(:admin) { create(:user, :admin) }

    let(:valid_params) do
      { provider_name: "AlphaVantage", provider_type: "Stocks & Forex", api_key_encrypted: "sk-test-key" }
    end

    it "creates integration and returns Success" do
      result = described_class.call(admin: admin, params: valid_params)

      expect(result).to be_success
      integration = result.value!
      expect(integration).to be_persisted
      expect(integration.provider_name).to eq("AlphaVantage")
      expect(integration.connection_status).to eq("disconnected")
    end

    it "publishes IntegrationConnected event" do
      expect(EventBus).to receive(:publish).with(an_instance_of(Administration::Events::IntegrationConnected))

      described_class.call(admin: admin, params: valid_params)
    end

    it "creates a default pool key when api_key_encrypted is provided" do
      result = described_class.call(admin: admin, params: valid_params.merge(api_key_encrypted: "sk-123"))

      expect(result).to be_success
      integration = result.value!
      default_key = integration.api_key_pools.default_key.first
      expect(default_key).to be_present
      expect(default_key.api_key_encrypted).to eq("sk-123")
    end

    it "returns Failure for missing provider_name" do
      result = described_class.call(admin: admin, params: { provider_type: "Stocks & Forex" })

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end

    it "returns Failure for duplicate provider_name" do
      create(:integration, provider_name: "AlphaVantage")

      result = described_class.call(admin: admin, params: valid_params)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end
  end
end
