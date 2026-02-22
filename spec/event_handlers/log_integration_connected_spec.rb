require "rails_helper"

RSpec.describe LogIntegrationConnected do
  describe ".call" do
    it "creates a SystemLog entry" do
      expect {
        described_class.call(integration_id: 1, provider_name: "Polygon.io")
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("Integration Connected: Polygon.io")
      expect(log.severity).to eq("success")
    end
  end
end
