require "rails_helper"

RSpec.describe MarketData::Handlers::BroadcastFundamentalsUpdate do
  let(:asset) { create(:asset, symbol: "AAPL") }
  let(:event) do
    MarketData::Events::AssetFundamentalsUpdated.new(
      asset_id: asset.id,
      symbol: asset.symbol,
      source: "calculated_from_statements"
    )
  end

  it "broadcasts Turbo Stream replace" do
    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      .with("asset_#{asset.id}",
        target: "asset_fundamentals_#{asset.id}",
        partial: "components/asset_fundamentals",
        locals: { asset: asset })

    described_class.call(event)
  end

  it "skips when asset not found" do
    bad_event = MarketData::Events::AssetFundamentalsUpdated.new(asset_id: -1, symbol: "FAKE", source: "test")

    expect(Turbo::StreamsChannel).not_to receive(:broadcast_replace_to)

    described_class.call(bad_event)
  end

  it "handles Hash events (async deserialization)" do
    hash_event = { asset_id: asset.id, symbol: asset.symbol, source: "test" }

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
    described_class.call(hash_event)
  end
end
