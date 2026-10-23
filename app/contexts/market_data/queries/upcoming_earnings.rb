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
      # hold several rows for a quarter. A row is superseded when another, touched
      # on a later day, lands in the same quarter; a reported quarter is past,
      # and a different quarter is not a re-dated estimate of this one.
      CURRENT_WINDOW_BEFORE = 14.days
      HORIZON = 1.year
      SAME_QUARTER = 60

      def self.within(days:, from: Date.current)
        ids = current(from).values.select { |event| event.report_date <= from + days.days }.map(&:id)
        EarningsEvent.where(id: ids).includes(:asset)
      end

      # The next date for one asset, however far off, or nil.
      def self.next_for(asset:, from: Date.current)
        current(from, asset_id: asset.id)[asset.id]
      end

      def self.current(from, asset_id: nil)
        scope = EarningsEvent.where(report_date: (from - CURRENT_WINDOW_BEFORE)..(from + HORIZON))
        scope = scope.where(asset_id: asset_id) if asset_id
        scope.to_a.group_by(&:asset_id).transform_values { |rows| next_live(rows, from) }.compact
      end

      def self.next_live(rows, from)
        rows.select { |row| row.actual_eps.nil? && row.report_date >= from && !superseded?(row, rows) }
            .min_by(&:report_date)
      end

      def self.superseded?(row, rows)
        touched = row.updated_at.to_date
        rows.any? { |other| other.updated_at.to_date > touched && (other.report_date - row.report_date).abs <= SAME_QUARTER }
      end
      private_class_method :current, :next_live, :superseded?
    end
  end
end
