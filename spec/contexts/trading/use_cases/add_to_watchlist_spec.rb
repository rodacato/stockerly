require "rails_helper"

RSpec.describe Trading::AddToWatchlist do
  let(:user) { create(:user) }
  let(:asset) { create(:asset) }

  describe ".call" do
    it "adds asset to user watchlist" do
      result = described_class.call(user: user, asset_id: asset.id)

      expect(result).to be_success
      expect(user.watchlist_items.count).to eq(1)
      expect(result.value!.asset).to eq(asset)
    end

    it "returns Failure when asset not found" do
      result = described_class.call(user: user, asset_id: 0)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:not_found)
    end

    it "returns Failure when asset already in watchlist" do
      create(:watchlist_item, user: user, asset: asset)
      result = described_class.call(user: user, asset_id: asset.id)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:validation)
    end
  end
end
