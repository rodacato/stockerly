require "rails_helper"

RSpec.describe MarketData::Handlers::LogFundamentalsUpdate do
  describe ".call" do
    let(:event) do
      MarketData::Events::AssetFundamentalsUpdated.new(
        asset_id: 1,
        symbol: "AAPL",
        source: "alpha_vantage_overview"
      )
    end

    it "creates a SystemLog entry" do
      expect { described_class.call(event) }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("Fundamentals Update: AAPL")
      expect(log.module_name).to eq("sync")
      expect(log.severity).to eq("success")
      expect(log.error_message).to eq("Source: alpha_vantage_overview")
    end

    it "works with Hash events (async deserialization)" do
      hash_event = { asset_id: 1, symbol: "MSFT", source: "calculated" }
      expect { described_class.call(hash_event) }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("Fundamentals Update: MSFT")
    end
  end
end
