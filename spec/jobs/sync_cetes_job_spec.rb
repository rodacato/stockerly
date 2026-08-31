require "rails_helper"

RSpec.describe SyncCetesJob do
  describe "#perform" do
    it "logs a success when every term came back" do
      allow(MarketData::UseCases::SyncCetes).to receive(:call)
        .and_return(Dry::Monads::Success(synced: 4, unreachable: []))

      expect { described_class.new.perform }.to change(SystemLog, :count).by(1)

      log = SystemLog.last
      expect(log.task_name).to eq("CETES Sync")
      expect(log.severity).to eq("success")
    end

    # "CETES Sync" is monitored, and a success cures a pending alert — so a run
    # that reached some terms and not others must not read as one.
    it "warns rather than reporting success when a term was unreachable" do
      allow(MarketData::UseCases::SyncCetes).to receive(:call)
        .and_return(Dry::Monads::Success(synced: 3, unreachable: [ "364" ]))

      described_class.new.perform

      log = SystemLog.last
      expect(log.severity).to eq("warning")
      expect(log.error_message).to include("364")
    end

    it "logs an error when Banxico refused everything" do
      allow(MarketData::UseCases::SyncCetes).to receive(:call)
        .and_return(Dry::Monads::Failure([ :all_terms_unreachable, "Banxico refused every term: 28, 91, 182, 364" ]))

      described_class.new.perform

      expect(SystemLog.last.severity).to eq("error")
    end
  end
end
