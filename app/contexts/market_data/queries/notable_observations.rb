module MarketData
  module Queries
    # Public read API: the recent observations that carry an action verb,
    # for a given set of assets. ADR-002 — Trading must not reach into
    # TechnicalObservation itself, which is what the old dashboard did.
    class NotableObservations
      WINDOW_DAYS = 3

      def self.call(asset_ids:, limit: 3, window_days: WINDOW_DAYS)
        return TechnicalObservation.none if asset_ids.blank?

        TechnicalObservation
          .for_assets(asset_ids)
          .within_last(window_days)
          .where(observation_type: Domain::ObservationAction::ACTIONABLE_TYPES)
          .recent
          .includes(:asset)
          .limit(limit)
      end
    end
  end
end
