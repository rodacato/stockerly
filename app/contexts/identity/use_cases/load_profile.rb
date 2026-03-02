module Identity
  class LoadProfile < ApplicationUseCase
    def call(user:)
      watchlist_items = user.watchlist_items
                            .includes(:asset)
                            .order(created_at: :desc)

      Success({
        watchlist_items: watchlist_items
      })
    end
  end
end
