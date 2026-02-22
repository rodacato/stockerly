require "rails_helper"

RSpec.describe SyncIntegrationJob, type: :job do
  describe "#perform" do
    context "with Polygon.io integration" do
      let!(:integration) { create(:integration, provider_name: "Polygon.io", connection_status: :connected) }

      context "when connectivity test succeeds" do
        before { stub_polygon_price("AAPL") }

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
        before { stub_polygon_server_error }

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

    context "when integration does not exist" do
      it "does nothing" do
        expect {
          described_class.perform_now(-1)
        }.not_to change(SystemLog, :count)
      end
    end
  end
end
