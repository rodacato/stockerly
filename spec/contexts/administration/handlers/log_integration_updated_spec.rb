require "rails_helper"

RSpec.describe Administration::Handlers::LogIntegrationUpdated do
  describe ".call" do
    let(:event) { Administration::Events::IntegrationUpdated.new(integration_id: 1, provider_name: "Polygon.io", changes: { "daily_call_limit" => { from: 500, to: 1000 } }) }

    it "creates a system log entry" do
      expect { described_class.call(event) }.to change(SystemLog, :count).by(1)
    end

    it "logs with success severity" do
      described_class.call(event)
      log = SystemLog.last
      expect(log.task_name).to eq("Integration Updated: Polygon.io")
      expect(log.module_name).to eq("integrations")
      expect(log.severity).to eq("success")
    end
  end
end
