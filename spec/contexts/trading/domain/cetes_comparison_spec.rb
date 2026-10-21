require "rails_helper"

RSpec.describe Trading::Domain::CetesComparison do
  let(:from) { Date.new(2026, 9, 1) }
  let(:to) { Date.new(2026, 9, 29) }

  it "is nil when there is no CETES rate to start from" do
    expect(described_class.between(3.0, from, to)).to be_nil
  end

  it "judges the gap on the returns as the card prints them" do
    CetesRateHistory.record(term: "28", date: from, rate: 10.0)

    result = described_class.between(3.0, from, to)

    expect(result[:benchmark]).to be_within(0.2).of(0.8)
    expect(result[:points]).to eq((3.0.round(1) - result[:benchmark].round(1)).round(1))
    expect(result[:term]).to eq("28")
  end
end
