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

  def broadcast_locals_for(record)
    locals = nil
    allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to) { |_stream, opts| locals = opts[:locals] }
    described_class.call(event_for(record))
    locals
  end

  # D116: reading the calculated row alone swapped in a block missing every overview-only metric.
  it "fills the calculated row's gaps from the overview" do
    create(:asset_fundamental, asset: asset, period_label: "OVERVIEW", metrics: { "beta" => "1.8" })
    create(:asset_fundamental, asset: asset, period_label: "CALCULATED", source: "calculated",
      metrics: { "debt_to_equity" => "0.4" })

    presenter = broadcast_locals_for(asset)[:presenter]

    expect(presenter.metric("beta")).to eq("1.8")
    expect(presenter.metric("debt_to_equity")).to eq("0.4")
  end

  # The handler only ever looked for equity rows, so every coin sync broadcast the empty state.
  it "renders a coin's block from its own row" do
    coin = create(:asset, symbol: "BTC", asset_type: :crypto, current_price: 60_000)
    create(:asset_fundamental, asset: coin, period_label: "CRYPTO_MARKET", metrics: { "ath_price" => "73750" })

    locals = broadcast_locals_for(coin)

    expect(locals[:has_fundamentals]).to be true
    expect(locals[:presenter].metric("ath_price")).to eq("73750")
  end

  it "does nothing for an asset that no longer exists" do
    ghost = event_for(asset)
    asset.destroy!

    expect(Turbo::StreamsChannel).not_to receive(:broadcast_replace_to)
    expect { described_class.call(ghost) }.not_to raise_error
  end
end
