require "rails_helper"

RSpec.describe LogNewsSync do
  describe ".call" do
    it "creates a SystemLog entry with article count" do
      expect {
        described_class.call(count: 7)
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("News Sync")
      expect(log.module_name).to eq("sync")
      expect(log.severity).to eq("success")
      expect(log.error_message).to eq("7 new articles imported")
    end
  end
end
