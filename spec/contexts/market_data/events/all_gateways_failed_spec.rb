require "rails_helper"

RSpec.describe MarketData::Events::AllGatewaysFailed do
  it "creates a valid event" do
    event = described_class.new(
      asset_id: 1,
      symbol: "AAPL",
      attempted_gateways: %w[MarketData::Gateways::PolygonGateway MarketData::Gateways::YahooFinanceGateway]
    )

    expect(event.asset_id).to eq(1)
    expect(event.symbol).to eq("AAPL")
    expect(event.attempted_gateways).to eq(%w[MarketData::Gateways::PolygonGateway MarketData::Gateways::YahooFinanceGateway])
    expect(event.occurred_at).to be_present
  end

  it "responds to event_name" do
    event = described_class.new(
      asset_id: 1, symbol: "AAPL", attempted_gateways: []
    )

    expect(event.event_name).to eq("market_data.events.all_gateways_failed")
  end
end
