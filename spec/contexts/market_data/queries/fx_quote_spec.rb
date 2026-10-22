require "rails_helper"

RSpec.describe MarketData::Queries::FxQuote do
  before do
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 1), rate: 17.1234, source: "Banxico/SF43718")
    FxRateHistory.record(base: "USD", quote: "MXN", date: Date.new(2026, 5, 4), rate: 17.3456, source: "Banxico/SF43718")
  end

  it "reads the rate in force on a date, saying which day it is really for" do
    quote = described_class.call(date: Date.new(2026, 5, 3))

    expect(quote).to eq(base: "USD", quote: "MXN", rate: BigDecimal("17.1234"), rate_date: Date.new(2026, 5, 1), source: "Banxico/SF43718")
  end

  it "has nothing before the series starts" do
    expect(described_class.call(date: Date.new(2026, 4, 1))).to be_nil
  end
end
