require "rails_helper"

RSpec.describe NotifyMaturitiesJob, type: :job do
  it "delegates to Trading::UseCases::NotifyApproachingMaturities" do
    allow(Trading::UseCases::NotifyApproachingMaturities).to receive(:call).and_return(Dry::Monads::Success(3))
    described_class.perform_now

    expect(Trading::UseCases::NotifyApproachingMaturities).to have_received(:call)
    expect(SystemLog.last.error_message).to eq("3 notifications sent")
  end

  it "logs the failure and re-raises when notifying blows up" do
    allow(Trading::UseCases::NotifyApproachingMaturities).to receive(:call).and_raise(StandardError, "boom")

    expect { described_class.perform_now }.to raise_error(StandardError, "boom")

    log = SystemLog.last
    expect(log.task_name).to eq("Maturity Notifications")
    expect(log.severity).to eq("error")
    expect(log.error_message).to eq("boom")
  end
end
