require "rails_helper"

RSpec.describe SyncEarningsJob do
  include ActiveJob::TestHelper

  describe "#perform" do
    context "when sync succeeds" do
      before do
        allow(MarketData::UseCases::SyncEarnings).to receive(:call)
          .and_return(Dry::Monads::Success(5))
      end

      it "logs success with event count" do
        expect { described_class.perform_now }
          .to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.task_name).to eq("Earnings Sync")
        expect(log.severity).to eq("success")
        expect(log.error_message).to include("5 events synced")
      end
    end

    # SyncEarnings returns Success unconditionally, so the only failure an
    # operator can ever see here is a raise.
    context "when the sync raises" do
      before do
        allow(MarketData::UseCases::SyncEarnings).to receive(:call)
          .and_raise(StandardError, "Connection timeout")
      end

      it "logs the failure and re-raises so the queue records it" do
        expect { described_class.perform_now }.to raise_error(StandardError, "Connection timeout")

        log = SystemLog.last
        expect(log.task_name).to eq("Earnings Sync")
        expect(log.severity).to eq("error")
        expect(log.error_message).to include("Connection timeout")
      end
    end
  end
end
