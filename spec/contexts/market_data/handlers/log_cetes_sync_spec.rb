require "rails_helper"

RSpec.describe MarketData::LogCetesSync do
  describe ".call" do
    it "creates a SystemLog entry with sync count" do
      event = MarketData::CetesSynced.new(count: 4)

      expect { described_class.call(event) }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("CETES Sync")
      expect(log.module_name).to eq("sync")
      expect(log.severity).to eq("success")
      expect(log.error_message).to eq("4 CETES terms synced")
    end
  end
end
