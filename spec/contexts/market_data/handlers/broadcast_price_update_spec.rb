require "rails_helper"

RSpec.describe MarketData::Handlers::BroadcastPriceUpdate do
  describe ".call" do
    let(:asset) { create(:asset, symbol: "AAPL", current_price: 150) }

    it "broadcasts replace via Turbo Streams" do
      allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

      described_class.call(asset_id: asset.id)

      expect(Turbo::StreamsChannel).to have_received(:broadcast_replace_to).with(
        "asset_#{asset.id}",
        target: "asset_price_#{asset.id}",
        partial: "components/asset_price",
        locals: { asset: asset }
      )
    end

    it "does nothing when asset not found" do
      allow(Turbo::StreamsChannel).to receive(:broadcast_replace_to)

      described_class.call(asset_id: -1)

      expect(Turbo::StreamsChannel).not_to have_received(:broadcast_replace_to)
    end
  end
end
