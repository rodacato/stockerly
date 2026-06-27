require "rails_helper"

RSpec.describe Trading::Handlers::RecordWatchlistItemAddedActivity do
  describe ".call" do
    let(:user)  { create(:user) }
    let(:asset) { create(:asset, symbol: "NVDA") }

    let(:event) do
      Trading::Events::WatchlistItemAdded.new(
        watchlist_item_id: 1, user_id: user.id, asset_id: asset.id, asset_symbol: asset.symbol
      )
    end

    it "records a watchlist_item_added activity" do
      expect {
        described_class.call(event)
      }.to change(UserActivity, :count).by(1)

      activity = UserActivity.last
      expect(activity.user).to eq(user)
      expect(activity.action).to eq("watchlist_item_added")
      expect(activity.params).to eq("asset_symbol" => "NVDA")
    end

    it "subscribes via EventBus and fires on WatchlistItemAdded publish" do
      load Rails.root.join("config/initializers/event_subscriptions.rb")

      expect {
        EventBus.publish(event)
      }.to change(UserActivity.by_action("watchlist_item_added"), :count).by(1)
    end
  end
end
