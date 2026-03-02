module Trading
  class RemoveFromWatchlist < ApplicationUseCase
    def call(user:, watchlist_item_id:)
      item = yield find_item(user, watchlist_item_id)
      item.destroy!

      Success(item)
    end

    private

    def find_item(user, id)
      item = user.watchlist_items.find_by(id: id)
      item ? Success(item) : Failure([ :not_found, "Watchlist item not found" ])
    end
  end
end
