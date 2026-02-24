require "rails_helper"

RSpec.describe SyncEarningsJob do
  include ActiveJob::TestHelper

  describe "#perform" do
    context "when sync succeeds" do
      before do
        allow(Earnings::SyncCalendar).to receive(:call)
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

    context "when sync fails" do
      before do
        allow(Earnings::SyncCalendar).to receive(:call)
          .and_return(Dry::Monads::Failure([ :gateway_error, "Connection timeout" ]))
      end

      it "logs failure with error message" do
        expect { described_class.perform_now }
          .to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.task_name).to eq("Earnings Sync")
        expect(log.severity).to eq("error")
        expect(log.error_message).to include("Connection timeout")
      end
    end
  end
end
