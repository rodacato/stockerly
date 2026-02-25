require "rails_helper"

RSpec.describe NotifyEarningsJob, type: :job do
  it "delegates to Earnings::NotifyApproaching" do
    allow(Earnings::NotifyApproaching).to receive(:call).and_return(Dry::Monads::Success(5))
    described_class.perform_now
    expect(Earnings::NotifyApproaching).to have_received(:call)
  end
end
