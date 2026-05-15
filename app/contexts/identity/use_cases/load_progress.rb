module Identity
  module UseCases
    # ADR-006: pure read, no failure path → SimpleUseCase.
    class LoadProgress < SimpleUseCase
      def call(user:)
        user.watchlist_items.count
      end
    end
  end
end
