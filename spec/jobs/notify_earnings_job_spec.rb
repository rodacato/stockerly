require "rails_helper"

RSpec.describe NotifyEarningsJob, type: :job do
  it "delegates to MarketData::UseCases::NotifyApproachingEarnings" do
    allow(MarketData::UseCases::NotifyApproachingEarnings).to receive(:call).and_return(Dry::Monads::Success(5))
    described_class.perform_now
    expect(MarketData::UseCases::NotifyApproachingEarnings).to have_received(:call)
  end
end
