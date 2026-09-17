require "rails_helper"

RSpec.describe DetectTechnicalObservationsJob, type: :job do
  it "runs the detector for the calendar it was scheduled for" do
    allow(MarketData::UseCases::DetectTechnicalObservations).to receive(:call).and_return(4)
    described_class.perform_now("crypto")

    expect(MarketData::UseCases::DetectTechnicalObservations).to have_received(:call).with(calendar: :crypto)
    expect(SystemLog.last.error_message).to eq("4 observations detected")
  end

  it "logs the failure and re-raises when the detector blows up" do
    allow(MarketData::UseCases::DetectTechnicalObservations).to receive(:call).and_raise(StandardError, "boom")

    expect { described_class.perform_now("equities") }.to raise_error(StandardError, "boom")

    log = SystemLog.last
    expect(log.task_name).to eq("Technical Observations")
    expect(log.severity).to eq("error")
    expect(log.error_message).to eq("boom")
  end
end
