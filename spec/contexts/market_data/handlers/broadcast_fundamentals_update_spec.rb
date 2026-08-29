require "rails_helper"

RSpec.describe MarketData::Handlers::BroadcastFundamentalsUpdate do
  let(:asset) { create(:asset, :stock, symbol: "NVDA", current_price: 120) }

  def event_for(record) = MarketData::Events::AssetFundamentalsUpdated.new(asset_id: record.id, symbol: record.symbol, source: "test")

  it "replaces the block on the asset's own channel" do
    create(:asset_fundamental, asset: asset, period_label: "OVERVIEW", metrics: { "pe_ratio" => "20" })

    expect(Turbo::StreamsChannel).to receive(:broadcast_replace_to)
      .with("asset_#{asset.id}", hash_including(target: "asset_fundamentals_#{asset.id}"))

    described_class.call(event_for(asset))
  end

  # The reader is looking at the pending state when this fires, so a broadcast
  # that renders the empty state again would read as a failed sync.
  it "renders the block as having data once a fundamental exists" do
    create(:asset_fundamental, asset: asset, period_label: "OVERVIEW", metrics: { "pe_ratio" => "20" })

    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to) do |_stream, opts|
      expect(opts[:locals][:has_fundamentals]).to be true
      expect(opts[:locals][:pending]).to be false
    end

    described_class.call(event_for(asset))
  end

  it "does nothing for an asset that no longer exists" do
    ghost = event_for(asset)
    asset.destroy!

    expect(Turbo::StreamsChannel).not_to receive(:broadcast_replace_to)
    expect { described_class.call(ghost) }.not_to raise_error
  end
end
