require "rails_helper"

RSpec.describe DetectTechnicalObservationsJob, type: :job do
  it "delegates to MarketData::UseCases::DetectTechnicalObservations" do
    allow(MarketData::UseCases::DetectTechnicalObservations).to receive(:call).and_return(Dry::Monads::Success(4))
    described_class.perform_now
    expect(MarketData::UseCases::DetectTechnicalObservations).to have_received(:call)
  end
end
