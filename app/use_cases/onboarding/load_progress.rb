module Onboarding
  class LoadProgress < ApplicationUseCase
    def call(user:)
      watchlist_count = user.watchlist_items.count

      Success({
        watchlist_count: watchlist_count
      })
    end
  end
end
