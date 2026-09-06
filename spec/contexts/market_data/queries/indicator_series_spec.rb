require "rails_helper"

RSpec.describe MarketData::Queries::IndicatorSeries do
  let(:asset) { create(:asset, :stock, symbol: "NVDA") }

  def seed(days)
    days.downto(0) do |i|
      create(:asset_price_history, asset: asset, date: i.days.ago.to_date, close: 100 + (i % 10))
    end
  end

  it "answers with one point per date for each line the chart draws" do
    seed(60)

    result = described_class.call(asset: asset)

    expect(result.keys).to contain_exactly(:rsi, :bb_upper, :bb_lower)
    expect(result[:rsi].first.keys).to contain_exactly(:time, :value)
    expect(result[:rsi].pluck(:value)).to all(be_between(0, 100))
  end

  # The reason this reads the whole series and slices afterwards. Wilder's RSI
  # is path-dependent, so a window seeded at its own first close draws a line
  # that disagrees with the number the Señales card prints from the same closes.
  it "carries the history before the window rather than seeding at its edge" do
    seed(120)
    from = 10.days.ago.to_date

    windowed = described_class.call(asset: asset, from: from)[:rsi].first

    closes = MarketData::Queries::PriceSeries.for(asset).closes_by_date
    expected = MarketData::Domain::TechnicalIndicators.rsi(closes.select { |date, _| date <= from }.values)

    expect(windowed[:time]).to eq(from.to_s)
    expect(windowed[:value]).to eq(expected)
  end

  it "starts the window where it was asked to, not at the first close on file" do
    seed(120)
    from = 10.days.ago.to_date

    result = described_class.call(asset: asset, from: from)

    expect(result[:rsi].pluck(:time).min).to eq(from.to_s)
    expect(result[:bb_upper].size).to eq(11)
  end

  # Absence, not a flat line at zero: an asset whose sync has not run yet has
  # no indicator, and inventing one would be worse than the gap.
  it "answers with nothing at all when the asset has no closes on file" do
    expect(described_class.call(asset: asset)).to eq({})
  end

  it "omits the dates that fall inside each indicator's own warm-up" do
    seed(25)

    result = described_class.call(asset: asset)

    expect(result[:rsi].size).to eq(12)
    expect(result[:bb_upper].size).to eq(7)
  end
end
