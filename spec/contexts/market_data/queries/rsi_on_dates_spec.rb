require "rails_helper"

RSpec.describe MarketData::Queries::RsiOnDates do
  let(:asset) { create(:asset, :stock, symbol: "NVDA") }

  def seed(days)
    days.downto(0) do |i|
      create(:asset_price_history, asset: asset, date: i.days.ago.to_date, close: 100 + (i % 10))
    end
  end

  it "answers for a past date from the closes before it, not from today's" do
    seed(60)

    result = described_class.call(asset: asset, dates: [ 30.days.ago.to_date, 10.days.ago.to_date ])

    expect(result.keys).to contain_exactly(30.days.ago.to_date, 10.days.ago.to_date)
    expect(result.values).to all(be_between(0, 100))
  end

  # The honest gap: RSI(14) needs 15 closes behind the date, and a purchase
  # older than the asset's history has none.
  it "omits a date with too little history behind it" do
    seed(20)

    result = described_class.call(asset: asset, dates: [ 19.days.ago.to_date, 2.days.ago.to_date ])

    expect(result).not_to have_key(19.days.ago.to_date)
    expect(result).to have_key(2.days.ago.to_date)
  end

  it "returns nothing when the asset has almost no history" do
    seed(5)

    expect(described_class.call(asset: asset, dates: [ Date.current ])).to be_empty
  end

  it "returns nothing when asked for nothing" do
    seed(60)

    expect(described_class.call(asset: asset, dates: [])).to eq({})
    expect(described_class.call(asset: asset, dates: nil)).to eq({})
  end

  it "reads the same closes once for many dates" do
    seed(60)
    dates = (1..10).map { |i| (i * 3).days.ago.to_date }

    expect { described_class.call(asset: asset, dates: dates) }.to make_queries(at_most: 1)
  end
end
