require "rails_helper"

RSpec.describe Administration::Assets::DeleteAsset do
  let(:admin) { create(:user, :admin) }

  describe "#call" do
    it "deletes the asset and returns its symbol" do
      asset = create(:asset, symbol: "AAPL")
      result = described_class.call(asset_id: asset.id, admin: admin)

      expect(result).to be_success
      expect(result.value!).to eq("AAPL")
      expect(Asset.find_by(id: asset.id)).to be_nil
    end

    it "publishes AssetDeleted event" do
      asset = create(:asset, symbol: "BTC")
      allow(EventBus).to receive(:publish)

      described_class.call(asset_id: asset.id, admin: admin)

      expect(EventBus).to have_received(:publish).with(an_instance_of(MarketData::Events::AssetDeleted))
    end

    it "cascades deletion to watchlist items" do
      asset = create(:asset)
      user = create(:user)
      create(:watchlist_item, user: user, asset: asset)

      expect { described_class.call(asset_id: asset.id, admin: admin) }
        .to change(WatchlistItem, :count).by(-1)
    end

    it "cascades deletion to positions and trades" do
      asset = create(:asset)
      portfolio = create(:portfolio)
      position = create(:position, asset: asset, portfolio: portfolio)
      create(:trade, asset: asset, portfolio: portfolio, position: position)

      expect { described_class.call(asset_id: asset.id, admin: admin) }
        .to change(Position, :count).by(-1)
        .and change(Trade, :count).by(-1)
    end

    it "cascades deletion to price history" do
      asset = create(:asset)
      create(:asset_price_history, asset: asset)

      expect { described_class.call(asset_id: asset.id, admin: admin) }
        .to change(AssetPriceHistory, :count).by(-1)
    end

    it "returns failure when asset not found" do
      result = described_class.call(asset_id: 999, admin: admin)

      expect(result).to be_failure
      expect(result.failure.first).to eq(:not_found)
    end
  end
end
