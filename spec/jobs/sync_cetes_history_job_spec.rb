require "rails_helper"

RSpec.describe SyncCetesHistoryJob do
  let(:from) { Date.new(2026, 1, 1) }
  let(:to) { Date.new(2026, 2, 1) }

  before do
    allow(MarketData::Gateways::BanxicoGateway).to receive(:new).and_return(
      MarketData::Gateways::BanxicoGateway.new(api_key: "test_token")
    )
  end

  def stub_every_term(auctions)
    MarketData::Gateways::BanxicoGateway.cetes_terms.each_with_index do |term, index|
      stub_banxico_auction_series(term: term, from: from, to: to,
                                  auctions: [ { fecha: "0#{index + 1}/01/2026", dato: auctions } ])
    end
  end

  it "stores the auctions the range returned" do
    stub_every_term("10.15")

    expect { described_class.perform_now(from: from, to: to) }.to change(CetesRateHistory, :count).by(4)
  end

  # The product tracks four instruments; this job recorded history for one of
  # them, so three CETES had no curve at all to compare a position against.
  it "covers every term, not only the twenty-eight day" do
    stub_every_term("9.5")

    described_class.perform_now(from: from, to: to)

    expect(CetesRateHistory.distinct.pluck(:term)).to match_array(%w[28 91 182 364])
  end

  it "still accepts a single term when one is asked for" do
    stub_every_term("9.5")

    described_class.perform_now(term: "91", from: from, to: to)

    expect(CetesRateHistory.distinct.pluck(:term)).to eq([ "91" ])
  end

  # A run that reached nothing must not log a success: "CETES History Sync" is
  # monitored, and a success there cures the alert the failure raised.
  it "reports an error rather than a success when Banxico refuses every term" do
    stub_request(:get, %r{series/SF\d+/datos/}).to_return(status: 500)

    expect { described_class.perform_now(from: from, to: to) }.not_to raise_error
    expect(SystemLog.last.severity).to eq("error")
  end

  it "reports a warning when one term is missing and the others answered" do
    stub_every_term("9.5")
    stub_request(:get, %r{series/SF43945/datos/}).to_return(status: 500)

    described_class.perform_now(from: from, to: to)

    expect(SystemLog.last.severity).to eq("warning")
    expect(SystemLog.last.error_message).to include("364")
  end
end
