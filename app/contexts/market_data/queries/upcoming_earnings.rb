module MarketData
  module Queries
    # Public read API: the earnings dates falling inside a window. ADR-002:
    # Trading must not reach into `EarningsEvent` from outside MarketData.
    #
    # The window is the caller's, not this query's — how far ahead an earnings
    # date is worth announcing is a notification policy, and MarketData has no
    # opinion on it.
    class UpcomingEarnings
      # The provider moves a date and the old row stays behind, so one asset can
      # hold three upcoming rows. The day touched last is the provider's current
      # answer (the nearest date among rows touched together); the rest are
      # superseded estimates and are not read.
      CURRENT_WINDOW_BEFORE = 14.days
      HORIZON = 1.year

      def self.within(days:, from: Date.current)
        EarningsEvent.where(id: current_ids(from - CURRENT_WINDOW_BEFORE, from + HORIZON), report_date: from..(from + days.days))
                     .includes(:asset)
      end

      # The next date for one asset, however far off, or nil.
      def self.next_for(asset:, from: Date.current)
        EarningsEvent.where(id: current_ids(from - CURRENT_WINDOW_BEFORE, from + HORIZON, asset_id: asset.id),
                            report_date: from..).first
      end

      def self.current_ids(first, last, asset_id: nil)
        scope = EarningsEvent.where(report_date: first..last)
        scope = scope.where(asset_id: asset_id) if asset_id
        scope.select("DISTINCT ON (asset_id) earnings_events.id").order("asset_id, updated_at::date DESC, report_date ASC")
      end
      private_class_method :current_ids
    end
  end
end
