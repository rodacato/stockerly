require "rails_helper"

RSpec.describe MarketData::Queries::CetesReinvestedReturn do
  def auction(rate, on:, term: "28")
    CetesRateHistory.record(term: term, date: on, rate: rate)
  end

  # 10% annual over 28 days, Mexican 360-day convention: 10/100 * 28/360.
  it "returns one term's simple yield when the period is exactly one term" do
    from = 28.days.ago.to_date
    auction(10.0, on: from)

    expect(described_class.call(from: from, to: Date.current)).to be_within(0.001).of(0.7778)
  end

  it "prorates a period shorter than the term" do
    from = 14.days.ago.to_date
    auction(10.0, on: from)

    expect(described_class.call(from: from, to: Date.current)).to be_within(0.001).of(0.3889)
  end

  # The point of the card: it rolls, so a rate change mid-period is felt.
  it "reinvests at the rate in force when the term rolls" do
    from = 56.days.ago.to_date
    auction(10.0, on: from)
    auction(20.0, on: 28.days.ago.to_date)

    # (1 + 0.10*28/360) * (1 + 0.20*28/360) - 1 = 0.0234543
    expect(described_class.call(from: from, to: Date.current)).to be_within(0.001).of(2.3454)
  end

  it "compounds rather than adding" do
    from = 56.days.ago.to_date
    auction(10.0, on: from)
    auction(10.0, on: 28.days.ago.to_date)

    simple_sum = 0.7778 * 2
    expect(described_class.call(from: from, to: Date.current)).to be > simple_sum
  end

  # Auctions are weekly, so the rate in force is almost never dated exactly
  # on the roll date.
  it "uses the most recent auction on or before the roll" do
    from = 28.days.ago.to_date
    auction(10.0, on: 40.days.ago.to_date)

    expect(described_class.call(from: from, to: Date.current)).to be_within(0.001).of(0.7778)
  end

  it "says it cannot compare when no rate precedes the period" do
    auction(10.0, on: 2.days.ago.to_date)

    expect(described_class.call(from: 60.days.ago.to_date, to: Date.current)).to be_nil
  end

  it "returns nil for an empty or inverted range" do
    auction(10.0, on: 60.days.ago.to_date)

    expect(described_class.call(from: Date.current, to: Date.current)).to be_nil
    expect(described_class.call(from: Date.current, to: 10.days.ago.to_date)).to be_nil
  end

  it "reads the term it was asked for, not the default" do
    from = 91.days.ago.to_date
    auction(10.0, on: from, term: "91")

    expect(described_class.call(term: "91", from: from, to: Date.current)).to be_within(0.001).of(2.5278)
    expect(described_class.call(term: "28", from: from, to: Date.current)).to be_nil
  end
end
