require "rails_helper"

RSpec.describe MarketData::Queries::NotableObservations do
  let(:aapl) { create(:asset, :stock, symbol: "AAPL") }
  let(:nvda) { create(:asset, :stock, symbol: "NVDA") }
  let(:other) { create(:asset, :stock, symbol: "TSLA") }

  def observe(asset, type, at: Time.current)
    TechnicalObservation.create!(asset: asset, observation_type: type, observed_at: at,
                                 indicator_snapshot: { rsi: 28 })
  end

  it "returns only observations for the asset ids it was given" do
    mine = observe(aapl, "rsi_oversold_entered")
    observe(other, "rsi_oversold_entered")

    expect(described_class.call(asset_ids: [ aapl.id ])).to contain_exactly(mine)
  end

  it "drops observation types that carry no verb" do
    observe(aapl, "rsi_oversold_exited")

    expect(described_class.call(asset_ids: [ aapl.id ])).to be_empty
  end

  it "drops observations older than the window" do
    observe(aapl, "rsi_oversold_entered", at: 10.days.ago)

    expect(described_class.call(asset_ids: [ aapl.id ])).to be_empty
  end

  it "returns the most recent first" do
    older = observe(aapl, "rsi_oversold_entered", at: 2.days.ago)
    newer = observe(nvda, "rsi_overbought_entered", at: 1.hour.ago)

    expect(described_class.call(asset_ids: [ aapl.id, nvda.id ]).to_a).to eq([ newer, older ])
  end

  it "returns nothing rather than everything when given no assets" do
    observe(aapl, "rsi_oversold_entered")

    expect(described_class.call(asset_ids: [])).to be_empty
  end
end
