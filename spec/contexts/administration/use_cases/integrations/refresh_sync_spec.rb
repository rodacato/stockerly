require "rails_helper"

RSpec.describe Administration::UseCases::Integrations::RefreshSync do
  describe "#call" do
    let!(:integration) { create(:integration, provider_name: "Polygon.io") }

    it "enqueues SyncIntegrationJob" do
      expect {
        described_class.call(integration_id: integration.id)
      }.to have_enqueued_job(SyncIntegrationJob).with(integration.id)
    end

    it "returns success" do
      result = described_class.call(integration_id: integration.id)

      expect(result).to be_success
    end

    it "returns failure when integration not found" do
      result = described_class.call(integration_id: -1)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:not_found)
    end
  end
end
