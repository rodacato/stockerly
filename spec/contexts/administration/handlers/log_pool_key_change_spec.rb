require "rails_helper"

RSpec.describe Administration::LogPoolKeyChange do
  describe ".call" do
    it "logs pool key addition with success severity" do
      event = Administration::PoolKeyAdded.new(integration_id: 1, pool_key_id: 1, key_name: "Production")
      expect { described_class.call(event) }.to change(SystemLog, :count).by(1)
      expect(SystemLog.last.task_name).to eq("Pool Key Added: Production")
      expect(SystemLog.last.severity).to eq("success")
    end

    it "logs pool key enable with success severity" do
      event = Administration::PoolKeyToggled.new(pool_key_id: 1, key_name: "Backup", enabled: true)
      described_class.call(event)
      expect(SystemLog.last.task_name).to eq("Pool Key Enabled: Backup")
    end

    it "logs pool key disable with success severity" do
      event = Administration::PoolKeyToggled.new(pool_key_id: 1, key_name: "Old Key", enabled: false)
      described_class.call(event)
      expect(SystemLog.last.task_name).to eq("Pool Key Disabled: Old Key")
    end

    it "logs pool key removal with warning severity" do
      event = Administration::PoolKeyRemoved.new(pool_key_id: 1, key_name: "Retired")
      described_class.call(event)
      expect(SystemLog.last.task_name).to eq("Pool Key Removed: Retired")
      expect(SystemLog.last.severity).to eq("warning")
    end
  end
end
