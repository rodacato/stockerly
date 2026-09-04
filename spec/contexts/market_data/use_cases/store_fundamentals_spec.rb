require "rails_helper"

RSpec.describe MarketData::UseCases::StoreFundamentals do
  let(:asset) { create(:asset, :stock, symbol: "AAPL") }
  let(:metrics) { { pe_ratio: 28.4, data_source: "AlphaVantage" } }

  it "stores the metrics under the equity label, with data_source lifted out" do
    described_class.call(asset: asset, metrics: metrics)

    row = AssetFundamental.find_by(asset: asset, period_label: described_class::EQUITY)
    expect(row.metrics).to eq("pe_ratio" => 28.4)
    expect(row.source).to eq("AlphaVantage")
  end

  it "leaves the caller's hash untouched" do
    described_class.call(asset: asset, metrics: metrics)

    expect(metrics).to include(data_source: "AlphaVantage")
  end

  it "overwrites the existing row for the same label rather than adding one" do
    described_class.call(asset: asset, metrics: metrics)

    expect { described_class.call(asset: asset, metrics: { pe_ratio: 31.0 }) }
      .not_to change(AssetFundamental, :count)
    expect(AssetFundamental.find_by(asset: asset).source).to eq("unknown")
  end

  it "keeps the crypto row separate from the equity one" do
    described_class.call(asset: asset, metrics: metrics)
    described_class.call(asset: asset, metrics: { market_cap: 1 }, period_label: described_class::CRYPTO)

    expect(AssetFundamental.where(asset: asset).count).to eq(2)
  end

  it "stamps fundamentals_synced_at on the asset" do
    expect { described_class.call(asset: asset, metrics: metrics) }
      .to change { asset.reload.fundamentals_synced_at }.from(nil)
  end

  it "publishes AssetFundamentalsUpdated" do
    received = []
    EventBus.subscribe(MarketData::Events::AssetFundamentalsUpdated, ->(event) { received << event })

    described_class.call(asset: asset, metrics: metrics)

    expect(received.map(&:symbol)).to eq([ "AAPL" ])
    expect(received.first.source).to eq("AlphaVantage")
  end

  # ADR-006's invariant: it has no failure path, so it must not hand the caller
  # a Result to unwrap.
  it "returns no Result" do
    expect(described_class.call(asset: asset, metrics: metrics)).not_to be_a(Dry::Monads::Result)
  end
end
