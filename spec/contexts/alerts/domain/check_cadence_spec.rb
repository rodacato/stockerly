require "rails_helper"

RSpec.describe Alerts::Domain::CheckCadence do
  it "gives price-driven rules the fastest price sync in the schedule" do
    cadence = described_class.for(build(:alert_rule, condition: :rsi_overbought, threshold_value: 70))

    expect(cadence.kind).to eq(:price_update)
    expect(cadence.minutes).to eq(5)
  end

  it "gives date rules the daily evaluation time from the schedule" do
    cadence = described_class.for(build(:alert_rule, :dividend, window_days: 3))

    expect(cadence.kind).to eq(:daily)
    expect(cadence.time).to eq("7:30")
    expect(cadence.minutes).to be_nil
  end
end
