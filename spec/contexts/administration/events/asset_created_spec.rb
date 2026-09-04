require "rails_helper"

RSpec.describe MarketData::Events::AssetCreated do
  it "creates an event with required attributes" do
    event = described_class.new(asset_id: 1, symbol: "AAPL", admin_id: 2)

    expect(event.asset_id).to eq(1)
    expect(event.symbol).to eq("AAPL")
    expect(event.admin_id).to eq(2)
    expect(event.occurred_at).to be_present
  end
end
