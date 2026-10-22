require "rails_helper"

RSpec.describe MarketData::Queries::MarketPulse do
  it "reads the major indices in their display order, as plain data" do
    create(:market_index, symbol: "SPX", name: "S&P 500", value: 5_800, change_percent: -0.4, is_open: false)
    create(:market_index, symbol: "IPC", name: "IPC Mexico", value: 54_000, change_percent: 0.6)
    create(:market_index, symbol: "VIX", name: "VIX", value: 18)

    indices = described_class.call[:indices]

    expect(indices.pluck(:symbol)).to eq(%w[IPC SPX])
    expect(indices.last).to include(value: 5_800, change_percent: -0.4, open: false)
    expect(indices).to all(be_a(Hash))
  end

  it "leaves out an index that has never been quoted" do
    create(:market_index, symbol: "NDX", value: nil, change_percent: nil)

    expect(described_class.call[:indices]).to be_empty
  end

  it "keeps the IPC read through NAFTRAC, which has a day change and no level" do
    create(:market_index, symbol: "IPC", name: "NAFTRAC · sigue al IPC", value: nil, change_percent: 0.4)

    expect(described_class.call[:indices].sole).to include(symbol: "IPC", value: nil, change_percent: 0.4)
  end

  it "reads the crypto sentiment with its classification as a key" do
    create(:fear_greed_reading, :extreme_fear)

    expect(described_class.call[:crypto_sentiment]).to include(value: 15, classification: "extreme_fear", source: "alternative.me")
  end

  it "does not serve a stale sentiment reading as today's" do
    create(:fear_greed_reading, :stale)

    expect(described_class.call[:crypto_sentiment]).to be_nil
  end
end
