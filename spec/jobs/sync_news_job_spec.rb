require "rails_helper"

RSpec.describe SyncNewsJob do
  include ActiveJob::TestHelper

  describe "#perform" do
    context "when sync succeeds" do
      before do
        allow(News::SyncArticles).to receive(:call)
          .and_return(Dry::Monads::Success(3))
      end

      it "logs success with article count" do
        expect { described_class.perform_now }
          .to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.task_name).to eq("News Sync")
        expect(log.severity).to eq("success")
        expect(log.error_message).to include("3 new articles")
      end
    end

    context "when sync fails" do
      before do
        allow(News::SyncArticles).to receive(:call)
          .and_return(Dry::Monads::Failure([:gateway_error, "Connection timeout"]))
      end

      it "logs failure with error message" do
        expect { described_class.perform_now }
          .to change(SystemLog, :count).by(1)

        log = SystemLog.last
        expect(log.task_name).to eq("News Sync")
        expect(log.severity).to eq("error")
        expect(log.error_message).to include("Connection timeout")
      end
    end
  end
end
