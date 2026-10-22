require "rails_helper"

RSpec.describe MarketData::Queries::CetesCurve do
  it "reads each term's latest auction, each with its own date" do
    CetesRateHistory.record(term: "28", date: Date.new(2026, 10, 8), rate: 7.40)
    CetesRateHistory.record(term: "28", date: Date.new(2026, 10, 15), rate: 7.25)
    CetesRateHistory.record(term: "364", date: Date.new(2026, 10, 1), rate: 7.80)

    expect(described_class.call).to eq([
      { term: 28, yield_rate: BigDecimal("7.25"), auction_date: Date.new(2026, 10, 15), source: "banxico" },
      { term: 364, yield_rate: BigDecimal("7.80"), auction_date: Date.new(2026, 10, 1), source: "banxico" }
    ])
  end

  it "is empty when no auction is stored" do
    expect(described_class.call).to eq([])
  end
end
