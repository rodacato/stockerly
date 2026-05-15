require "rails_helper"

RSpec.describe NotifyMaturitiesJob, type: :job do
  it "delegates to Trading::UseCases::NotifyApproachingMaturities" do
    allow(Trading::UseCases::NotifyApproachingMaturities).to receive(:call).and_return(Dry::Monads::Success(3))
    described_class.perform_now
    expect(Trading::UseCases::NotifyApproachingMaturities).to have_received(:call)
  end
end
