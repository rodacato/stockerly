require "rails_helper"

RSpec.describe SendDailyDigestJob, type: :job do
  include ActiveJob::TestHelper

  it "delivers the digest and records what it did" do
    user = create(:user)
    create(:alert_preference, user: user, email_digest: true)
    create(:notification, user: user, title: "AAPL cruzó USD 200.00 al alza")

    expect {
      perform_enqueued_jobs { described_class.perform_now }
    }.to change { ActionMailer::Base.deliveries.size }.by(1)

    log = SystemLog.where(task_name: "Daily Digest").last
    expect(log.severity).to eq("success")
    expect(log.error_message).to eq("1 digest(s) sent")
  end

  it "records a quiet day as a success with nothing sent" do
    described_class.perform_now

    expect(SystemLog.where(task_name: "Daily Digest").last.error_message).to eq("0 digest(s) sent")
  end

  it "logs the failure and re-raises when the digest blows up" do
    allow(Notifications::UseCases::SendDailyDigest).to receive(:call).and_raise(StandardError, "boom")

    expect { described_class.perform_now }.to raise_error(StandardError, "boom")

    log = SystemLog.where(task_name: "Daily Digest").last
    expect(log.severity).to eq("error")
    expect(log.error_message).to eq("boom")
  end
end
