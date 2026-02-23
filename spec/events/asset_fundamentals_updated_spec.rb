require "rails_helper"

RSpec.describe AssetFundamentalsUpdated do
  subject(:event) do
    described_class.new(
      asset_id: 1,
      symbol: "AAPL",
      source: "alpha_vantage_overview"
    )
  end

  it "has required attributes" do
    expect(event.asset_id).to eq(1)
    expect(event.symbol).to eq("AAPL")
    expect(event.source).to eq("alpha_vantage_overview")
  end

  it "inherits occurred_at from BaseEvent" do
    expect(event.occurred_at).to be_present
  end

  it "generates event_name" do
    expect(event.event_name).to eq("asset_fundamentals_updated")
  end
end
