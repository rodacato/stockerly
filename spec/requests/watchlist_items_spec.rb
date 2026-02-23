require "rails_helper"

RSpec.describe "WatchlistItems", type: :request do
  let!(:user) { create(:user, email: "wl@example.com", password: "password123") }
  let!(:onboarding_asset) { create(:asset) }
  let!(:asset) { create(:asset) }

  before do
    login_as(user)
  end

  describe "POST /watchlist_items" do
    it "adds asset to watchlist and redirects" do
      expect {
        post watchlist_items_path, params: { asset_id: asset.id }
      }.to change(WatchlistItem, :count).by(1)

      expect(response).to redirect_to(dashboard_path)
    end

    it "responds with turbo_stream format" do
      post watchlist_items_path, params: { asset_id: asset.id }, as: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end

  describe "DELETE /watchlist_items/:id" do
    it "removes item from watchlist and redirects" do
      item = create(:watchlist_item, user: user, asset: asset)

      expect {
        delete watchlist_item_path(item)
      }.to change(WatchlistItem, :count).by(-1)

      expect(response).to redirect_to(profile_path)
    end

    it "responds with turbo_stream format" do
      item = create(:watchlist_item, user: user, asset: asset)

      delete watchlist_item_path(item), as: :turbo_stream
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
