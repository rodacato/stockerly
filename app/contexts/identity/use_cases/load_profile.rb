module Identity
  module UseCases
    class LoadProfile < ApplicationUseCase
      def call(user:)
        watchlist_items = user.watchlist_items
                              .includes(asset: :asset_price_histories)
                              .order(created_at: :desc)

        Success({
          watchlist_items: watchlist_items
        })
      end
    end
  end
end
