require "rails_helper"

RSpec.describe MarketData::Events::DividendsSynced do
  subject(:event) { described_class.new(asset_count: 3, dividend_count: 12) }

  it "stores asset_count" do
    expect(event.asset_count).to eq(3)
  end

  it "stores dividend_count" do
    expect(event.dividend_count).to eq(12)
  end

  it "includes occurred_at from BaseEvent" do
    expect(event.occurred_at).to respond_to(:to_time)
  end
end
