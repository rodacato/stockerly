require "rails_helper"

RSpec.describe NotifyEarningsJob, type: :job do
  it "delegates to MarketData::NotifyApproachingEarnings" do
    allow(MarketData::NotifyApproachingEarnings).to receive(:call).and_return(Dry::Monads::Success(5))
    described_class.perform_now
    expect(MarketData::NotifyApproachingEarnings).to have_received(:call)
  end
end
