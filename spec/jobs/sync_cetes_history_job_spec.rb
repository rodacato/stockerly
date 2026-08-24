require "rails_helper"

RSpec.describe SyncCetesHistoryJob do
  it "stores the auctions the range returned" do
    from = Date.new(2026, 1, 1)
    to = Date.new(2026, 2, 1)
    stub_banxico_auction_series(from: from, to: to, auctions: [ { fecha: "08/01/2026", dato: "10.15" } ])
    allow(MarketData::Gateways::BanxicoGateway).to receive(:new).and_return(
      MarketData::Gateways::BanxicoGateway.new(api_key: "test_token")
    )

    expect { described_class.perform_now(from: from, to: to) }.to change(CetesRateHistory, :count).by(1)
  end

  it "logs the failure instead of raising when Banxico is down" do
    stub_request(:get, %r{series/SF43936/datos/}).to_return(status: 500)
    allow(MarketData::Gateways::BanxicoGateway).to receive(:new).and_return(
      MarketData::Gateways::BanxicoGateway.new(api_key: "test_token")
    )

    expect { described_class.perform_now }.not_to raise_error
  end
end
