require "rails_helper"

RSpec.describe MarketData::UseCases::SyncCetesHistory do
  let(:from) { Date.new(2026, 1, 1) }
  let(:to)   { Date.new(2026, 2, 1) }

  def gateway = MarketData::Gateways::BanxicoGateway.new(api_key: "test_token")

  it "stores every auction the range returned" do
    stub_banxico_auction_series(from: from, to: to, auctions: [
      { fecha: "08/01/2026", dato: "10.15" },
      { fecha: "15/01/2026", dato: "10.05" },
      { fecha: "22/01/2026", dato: "9.95" }
    ])

    result = described_class.call(from: from, to: to, gateway: gateway)

    expect(result).to be_success
    expect(result.value![:stored]).to eq(3)
    expect(CetesRateHistory.rate_on(term: "28", date: Date.new(2026, 1, 20))).to eq(10.05)
  end

  it "is idempotent — a re-run updates rather than duplicating" do
    stub_banxico_auction_series(from: from, to: to, auctions: [ { fecha: "08/01/2026", dato: "10.15" } ])

    2.times { described_class.call(from: from, to: to, gateway: gateway) }

    expect(CetesRateHistory.count).to eq(1)
  end

  it "corrects a revised rate on re-run" do
    stub_banxico_auction_series(from: from, to: to, auctions: [ { fecha: "08/01/2026", dato: "10.15" } ])
    described_class.call(from: from, to: to, gateway: gateway)

    stub_banxico_auction_series(from: from, to: to, auctions: [ { fecha: "08/01/2026", dato: "10.40" } ])
    described_class.call(from: from, to: to, gateway: gateway)

    expect(CetesRateHistory.rate_on(term: "28", date: Date.new(2026, 1, 10))).to eq(10.40)
  end

  it "skips a non-publication day rather than storing a zero" do
    stub_banxico_auction_series(from: from, to: to, auctions: [
      { fecha: "08/01/2026", dato: "N/E" },
      { fecha: "15/01/2026", dato: "10.05" }
    ])

    expect(described_class.call(from: from, to: to, gateway: gateway).value![:stored]).to eq(1)
  end

  it "fails without raising when Banxico is unhappy" do
    stub_request(:get, %r{series/SF43936/datos/}).to_return(status: 500)

    expect(described_class.call(from: from, to: to, gateway: gateway)).to be_failure
  end
end
