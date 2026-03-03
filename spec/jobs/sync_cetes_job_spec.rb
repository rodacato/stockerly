require "rails_helper"

RSpec.describe SyncCetesJob do
  describe "#perform" do
    it "delegates to MarketData::UseCases::SyncCetes and logs success" do
      allow(MarketData::UseCases::SyncCetes).to receive(:call).and_return(Dry::Monads::Success(4))

      expect { described_class.new.perform }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("CETES Sync")
      expect(log.severity).to eq("success")
    end
  end
end
