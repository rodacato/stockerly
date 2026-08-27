module Trading
  module UseCases
    # Tracked — the third tier (D9). Not a peer tab: it is where the daily
    # sync budget is visible and where syncing can be paused. Absorbs the list
    # /admin/assets used to show, minus the admin costume (D5).
    class LoadTrackedAssets < SimpleUseCase
      def call(user:)
        held = user.portfolio&.open_positions&.pluck(:asset_id) || []
        followed = user.watchlist_items.pluck(:asset_id)

        {
          assets: Asset.order(:symbol),
          held_ids: held.to_set,
          followed_ids: followed.to_set,
          budget: MarketData::Domain::FundamentalsBudget.today
        }
      end
    end
  end
end
