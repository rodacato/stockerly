module Trading
  module UseCases
    # The Señales screen (D79). The Panorama shows three readings over three
    # days; this lifts that cap over the window D42 named when it un-gated the
    # screen — a week in which the Panorama's window hid something.
    #
    # Observations are read through MarketData's public query, never through
    # TechnicalObservation itself (ADR-002).
    class LoadSignals < SimpleUseCase
      WINDOW_DAYS = 7
      LIMIT = 50

      def call(user:)
        MarketData::Queries::NotableObservations.call(
          asset_ids: asset_ids_for(user),
          limit: LIMIT,
          window_days: WINDOW_DAYS
        )
      end

      private

      def asset_ids_for(user)
        held = user.portfolio&.open_positions&.pluck(:asset_id) || []
        (held + user.watchlist_items.pluck(:asset_id)).uniq
      end
    end
  end
end
