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

  # D127: the arrow draws the move the phrase states, never the verb.
  it "states the move each type describes" do
    expect(described_class::ACTIONABLE_TYPES.index_with { described_class.reading(_1).move })
      .to eq("rsi_oversold_entered" => :down, "bb_lower_breached" => :down,
             "ma200_crossed_above" => :up, "ma50_crossed_above" => :up,
             "rsi_overbought_entered" => :up, "bb_upper_breached" => :up,
             "ma200_crossed_below" => :down, "ma50_crossed_below" => :down)
  end

  # D127: crossings follow the trend, RSI and Bollinger bet on a reversal.
  it "names which reading each verb follows" do
    logics = described_class::ACTIONABLE_TYPES.index_with { described_class.reading(_1).logic }

    expect(logics.select { |type, _| type.start_with?("ma") }.values.uniq).to eq([ :trend ])
    expect(logics.reject { |type, _| type.start_with?("ma") }.values.uniq).to eq([ :reversion ])
  end

  it "only maps types the detector can actually persist" do
    expect(TechnicalObservation::TYPES).to include(*described_class::ACTIONABLE_TYPES)
  end
end
