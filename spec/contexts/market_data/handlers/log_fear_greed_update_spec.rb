require "rails_helper"

RSpec.describe MarketData::LogFearGreedUpdate do
  describe ".call" do
    it "creates a SystemLog entry" do
      expect {
        described_class.call(index_type: "crypto", value: 25, classification: "Extreme Fear")
      }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("Fear & Greed Update: crypto")
      expect(log.severity).to eq("success")
      expect(log.error_message).to eq("Value: 25 (Extreme Fear)")
    end
  end
end
