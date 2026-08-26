require "rails_helper"

RSpec.describe MarketData::Domain::AssetState, "trend" do
  let(:asset) { create(:asset, :stock) }

  def observation(type, at)
    create(:technical_observation, asset: asset, observation_type: type, observed_at: at)
  end

  it "returns the most recent moving-average crossing" do
    observation("ma50_crossed_above", 5.days.ago)
    latest = observation("ma200_crossed_below", 1.day.ago)

    expect(described_class.trend([ observation("rsi_overbought_entered", 2.hours.ago), latest ]).id).to eq(latest.id)
  end

  it "ignores RSI and Bollinger events, which are extension and not trend" do
    rsi = observation("rsi_oversold_entered", 1.day.ago)

    expect(described_class.trend([ rsi ])).to be_nil
  end

  it "reads a crossing above as bullish and below as bearish" do
    up   = observation("ma50_crossed_above", 2.days.ago)
    down = observation("ma200_crossed_below", 1.day.ago)

    expect(described_class.trend_direction(up)).to eq(:bullish)
    expect(described_class.trend_direction(down)).to eq(:bearish)
  end

  it "returns no direction without an observation" do
    expect(described_class.trend_direction(nil)).to be_nil
  end

  # The state must stay blind to trend — that is why TREND_ONLY exists.
  it "does not let a crossing change the state" do
    crossing = observation("ma200_crossed_below", 1.hour.ago)
    oversold = observation("rsi_oversold_entered", 3.days.ago)

    expect(described_class.for([ oversold, crossing ])).to eq(:oversold)
  end
end
