require "rails_helper"

# ADR-013 requires this mapping to live in one place and be covered. The point
# of the spec is the closed set: a verb may only come from a type that exists.
RSpec.describe MarketData::Domain::ObservationAction do
  it "maps oversold and upward crossings to a buy" do
    expect(described_class.for("rsi_oversold_entered")).to eq(:buy)
    expect(described_class.for("bb_lower_breached")).to eq(:buy)
    expect(described_class.for("ma200_crossed_above")).to eq(:buy)
  end

  it "maps overbought and downward crossings to a sell" do
    expect(described_class.for("rsi_overbought_entered")).to eq(:sell)
    expect(described_class.for("bb_upper_breached")).to eq(:sell)
    expect(described_class.for("ma50_crossed_below")).to eq(:sell)
  end

  it "gives no verb to an exit — returning to the middle is not an action" do
    expect(described_class.for("rsi_oversold_exited")).to be_nil
    expect(described_class.for("rsi_overbought_exited")).to be_nil
  end

  it "gives no verb to a type that does not exist" do
    expect(described_class.for("moon_phase_favourable")).to be_nil
    expect(described_class.for(nil)).to be_nil
  end

  it "only maps types the detector can actually persist" do
    expect(TechnicalObservation::TYPES).to include(*described_class::ACTIONABLE_TYPES)
  end
end
