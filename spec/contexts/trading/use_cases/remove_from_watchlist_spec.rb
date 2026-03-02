require "rails_helper"

RSpec.describe Trading::RemoveFromWatchlist do
  let(:user) { create(:user) }
  let(:asset) { create(:asset) }

  describe ".call" do
    it "removes asset from user watchlist" do
      item = create(:watchlist_item, user: user, asset: asset)
      result = described_class.call(user: user, watchlist_item_id: item.id)

      expect(result).to be_success
      expect(user.watchlist_items.count).to eq(0)
    end

    it "returns Failure when item not found" do
      result = described_class.call(user: user, watchlist_item_id: 0)

      expect(result).to be_failure
      expect(result.failure[0]).to eq(:not_found)
    end

    it "cannot remove another user's watchlist item" do
      other_user = create(:user, email: "other@example.com")
      item = create(:watchlist_item, user: other_user, asset: asset)

      result = described_class.call(user: user, watchlist_item_id: item.id)
      expect(result).to be_failure
    end
  end
end
