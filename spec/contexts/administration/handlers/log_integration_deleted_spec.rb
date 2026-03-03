require "rails_helper"

RSpec.describe Administration::Handlers::LogIntegrationDeleted do
  describe ".call" do
    let(:event) { Administration::Events::IntegrationDeleted.new(integration_id: 1, provider_name: "Old Provider") }

    it "creates a system log entry" do
      expect { described_class.call(event) }.to change(SystemLog, :count).by(1)
    end

    it "logs with warning severity" do
      described_class.call(event)
      log = SystemLog.last
      expect(log.task_name).to eq("Integration Deleted: Old Provider")
      expect(log.module_name).to eq("integrations")
      expect(log.severity).to eq("warning")
    end
  end
end
