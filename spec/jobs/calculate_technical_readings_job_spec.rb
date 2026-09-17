require "rails_helper"

RSpec.describe CalculateTechnicalReadingsJob, type: :job do
  it "logs how many readings it refreshed" do
    allow(MarketData::UseCases::RefreshTechnicalReadings).to receive(:call).and_return(12)

    described_class.perform_now

    expect(SystemLog.last).to have_attributes(task_name: "Technical Readings", error_message: "12 readings refreshed")
  end

  it "logs the failure and re-raises" do
    allow(MarketData::UseCases::RefreshTechnicalReadings).to receive(:call).and_raise(StandardError, "boom")

    expect { described_class.perform_now }.to raise_error(StandardError, "boom")
    expect(SystemLog.last).to have_attributes(task_name: "Technical Readings", severity: "error")
  end
end
