require "rails_helper"

RSpec.describe MarketData::Queries::IndexReturn do
  let(:index) { create(:market_index, symbol: "IPC") }

  def close(value, on:) = create(:market_index_history, market_index: index, date: on, close_value: value)

  let(:from) { 30.days.ago.to_date }
  let(:to) { Date.current }

  it "reads the change of the closes between the two dates" do
    close(50_000, on: from)
    close(52_000, on: to)

    expect(described_class.call(symbol: "IPC", from: from, to: to)).to be_within(0.001).of(4.0)
  end

  it "settles a weekend or holiday against the nearest prior close" do
    close(50_000, on: from - 2.days)
    close(55_000, on: to - 1.day)

    expect(described_class.call(symbol: "IPC", from: from, to: to)).to be_within(0.001).of(10.0)
  end

  it "has no answer when the opening close is older than the window" do
    close(50_000, on: from - 20.days)
    close(52_000, on: to)

    expect(described_class.call(symbol: "IPC", from: from, to: to)).to be_nil
  end

  it "has no answer for an index it does not hold, or an empty period" do
    expect(described_class.call(symbol: "NOPE", from: from, to: to)).to be_nil
    expect(described_class.call(symbol: "IPC", from: to, to: to)).to be_nil
  end
end
