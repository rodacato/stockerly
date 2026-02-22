require "rails_helper"

RSpec.describe WatchlistItem, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      item = build(:watchlist_item)
      expect(item).to be_valid
    end

    it "requires unique asset per user" do
      user = create(:user)
      asset = create(:asset)
      create(:watchlist_item, user: user, asset: asset)
      duplicate = build(:watchlist_item, user: user, asset: asset)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:asset_id]).to include("already in watchlist")
    end

    it "allows same asset for different users" do
      asset = create(:asset)
      create(:watchlist_item, user: create(:user), asset: asset)
      item = build(:watchlist_item, user: create(:user), asset: asset)
      expect(item).to be_valid
    end
  end

  describe "callbacks" do
    it "captures entry_price from asset on create" do
      asset = create(:asset, current_price: 189.43)
      item = create(:watchlist_item, asset: asset, entry_price: nil)
      expect(item.entry_price.to_f).to eq(189.43)
    end

    it "does not overwrite explicitly set entry_price" do
      asset = create(:asset, current_price: 189.43)
      item = create(:watchlist_item, asset: asset, entry_price: 180.0)
      expect(item.entry_price.to_f).to eq(180.0)
    end
  end
end
