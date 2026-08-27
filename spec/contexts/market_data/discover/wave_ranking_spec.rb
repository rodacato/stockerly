require "rails_helper"

RSpec.describe MarketData::Discover::WaveRanking do
  def series(*closes)
    closes.each_with_index.map { |close, i| { date: Date.current - (closes.size - i), close: close } }
  end

  let(:baskets) do
    [
      MarketData::Discover::BasketCatalogue::Basket.new(
        symbol: "SMH", name: "Semiconductores", group: "sectores", referents: [ "NVDA" ]
      ),
      MarketData::Discover::BasketCatalogue::Basket.new(
        symbol: "XLE", name: "Energía", group: "sectores", referents: [ "XOM" ]
      )
    ]
  end

  it "ranks by what each basket did, best first" do
    bars = { "SMH" => series(100, 108), "XLE" => series(100, 97), "SPY" => series(100, 103) }

    waves = described_class.call(bars: bars, baseline_symbol: "SPY", baskets: baskets)

    expect(waves.map(&:symbol)).to eq(%w[SMH XLE])
    expect(waves.first.change_percent).to eq(8.0)
  end

  it "measures each basket against the baseline rather than reporting it twice" do
    bars = { "SMH" => series(100, 108), "XLE" => series(100, 97), "SPY" => series(100, 103) }

    waves = described_class.call(bars: bars, baseline_symbol: "SPY", baskets: baskets)

    expect(waves.map(&:vs_baseline)).to eq([ 5.0, -6.0 ])
  end

  it "never returns the baseline as a wave of its own" do
    bars = { "SMH" => series(100, 108), "SPY" => series(100, 103) }

    waves = described_class.call(bars: bars, baseline_symbol: "SPY", baskets: baskets)

    expect(waves.map(&:symbol)).not_to include("SPY")
  end

  # "Did not move" and "we have no data" are different statements.
  it "drops a basket with too few closes instead of showing it flat" do
    bars = { "SMH" => series(100, 108), "XLE" => series(100), "SPY" => series(100, 103) }

    waves = described_class.call(bars: bars, baseline_symbol: "SPY", baskets: baskets)

    expect(waves.map(&:symbol)).to eq([ "SMH" ])
  end

  it "still ranks when the baseline itself is missing, without inventing a comparison" do
    bars = { "SMH" => series(100, 108), "XLE" => series(100, 97) }

    waves = described_class.call(bars: bars, baseline_symbol: "SPY", baskets: baskets)

    expect(waves.map(&:symbol)).to eq(%w[SMH XLE])
    expect(waves.map(&:vs_baseline)).to eq([ nil, nil ])
  end

  it "carries the closes the sparkline draws" do
    bars = { "SMH" => series(100, 104, 108), "SPY" => series(100, 103) }

    wave = described_class.call(bars: bars, baseline_symbol: "SPY", baskets: baskets).first

    expect(wave.closes).to eq([ 100.0, 104.0, 108.0 ])
  end
end
