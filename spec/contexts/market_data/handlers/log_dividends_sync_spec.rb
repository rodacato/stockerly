require "rails_helper"

RSpec.describe MarketData::LogDividendsSync do
  describe ".call" do
    it "creates a SystemLog entry with sync counts" do
      expect {
        described_class.call(asset_count: 3, dividend_count: 12)
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("Dividends Sync")
      expect(log.module_name).to eq("sync")
      expect(log.severity).to eq("success")
      expect(log.error_message).to eq("12 dividends synced across 3 assets")
    end
  end
end
