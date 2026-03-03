require "rails_helper"

RSpec.describe MarketData::Handlers::LogMarketIndicesUpdate do
  describe ".call" do
    it "creates a SystemLog entry with index count" do
      expect {
        described_class.call(count: 4)
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("Market Indices Sync")
      expect(log.module_name).to eq("sync")
      expect(log.severity).to eq("success")
      expect(log.error_message).to eq("4 indices updated")
    end
  end
end
