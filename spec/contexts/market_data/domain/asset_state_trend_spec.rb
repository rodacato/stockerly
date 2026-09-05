require "rails_helper"

RSpec.describe MarketData::Domain::AssetState, "trend blindness" do
  let(:asset) { create(:asset, :stock) }

  def observation(type, at)
    create(:technical_observation, asset: asset, observation_type: type, observed_at: at)
  end

  # TREND_ONLY exists so a crossing cannot move the state. It survived #586,
  # which retired the confluence semaphore that AssetState.trend fed: the
  # readers of a crossing are IndicatorSignals and the observation feed, and
  # neither goes through here.
  it "does not let a crossing change the state" do
    crossing = observation("ma200_crossed_below", 1.hour.ago)
    oversold = observation("rsi_oversold_entered", 3.days.ago)

    expect(described_class.for([ oversold, crossing ])).to eq(:oversold)
  end

  it "does not let a crossing become the state's source either" do
    observation("ma200_crossed_below", 1.hour.ago)
    oversold = observation("rsi_oversold_entered", 3.days.ago)

    expect(described_class.source([ oversold ]).id).to eq(oversold.id)
  end
end
