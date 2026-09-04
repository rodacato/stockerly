require "rails_helper"

RSpec.describe NotifyEarningsJob, type: :job do
  it "delegates to Trading::UseCases::NotifyApproachingEarnings" do
    allow(Trading::UseCases::NotifyApproachingEarnings).to receive(:call).and_return(5)
    described_class.perform_now

    expect(Trading::UseCases::NotifyApproachingEarnings).to have_received(:call)
    expect(SystemLog.last.error_message).to eq("5 notifications sent")
  end

  it "logs the failure and re-raises when notifying blows up" do
    allow(Trading::UseCases::NotifyApproachingEarnings).to receive(:call).and_raise(StandardError, "boom")

    expect { described_class.perform_now }.to raise_error(StandardError, "boom")

    log = SystemLog.last
    expect(log.task_name).to eq("Earnings Notifications")
    expect(log.severity).to eq("error")
    expect(log.error_message).to eq("boom")
  end
end
