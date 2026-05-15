module Trading
  module UseCases
    # ADR-006: single-resource mutation with the canonical 404 failure
    # path. `find` raises ActiveRecord::RecordNotFound; the controller
    # handles that with a flash + redirect.
    class RemoveFromWatchlist < SimpleUseCase
      def call(user:, watchlist_item_id:)
        item = user.watchlist_items.find(watchlist_item_id)
        item.destroy!
        item
      end
    end
  end
end
