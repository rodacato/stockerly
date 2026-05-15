require "rails_helper"

RSpec.describe Trading::UseCases::RemoveFromWatchlist do
  let(:user) { create(:user) }
  let(:asset) { create(:asset) }

  describe ".call" do
    it "removes the asset from the user's watchlist" do
      item = create(:watchlist_item, user: user, asset: asset)

      expect {
        described_class.call(user: user, watchlist_item_id: item.id)
      }.to change(user.watchlist_items, :count).from(1).to(0)
    end

    it "returns the destroyed (frozen) item so callers can use turbo_stream.remove" do
      item = create(:watchlist_item, user: user, asset: asset)
      result = described_class.call(user: user, watchlist_item_id: item.id)

      expect(result).to be_destroyed
    end

    it "raises ActiveRecord::RecordNotFound for an unknown item id" do
      expect {
        described_class.call(user: user, watchlist_item_id: 0)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "raises NotFound when targeting another user's item (scope = user.watchlist_items)" do
      other = create(:user, email: "other@example.com")
      item = create(:watchlist_item, user: other, asset: asset)

      expect {
        described_class.call(user: user, watchlist_item_id: item.id)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
