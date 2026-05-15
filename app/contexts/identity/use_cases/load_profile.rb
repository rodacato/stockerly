module Identity
  module UseCases
    # ADR-006: pure read, no failure path → SimpleUseCase.
    class LoadProfile < SimpleUseCase
      def call(user:)
        user.watchlist_items
            .includes(asset: :asset_price_histories)
            .order(created_at: :desc)
      end
    end
  end
end
