module MarketData
  module Queries
    # ADR-031: an asset's next report date and its last reported quarter, as
    # plain data. The next date is UpcomingEarnings' current answer, not a
    # superseded estimate.
    class AssetEarnings
      # @api public
      def self.call(symbol:)
        asset = AssetLookup.by_symbol(symbol)
        return nil unless asset

        { symbol: asset.symbol, next: upcoming(asset), last: reported(asset) }.freeze
      end

      def self.upcoming(asset)
        event = UpcomingEarnings.next_for(asset: asset)
        event && { report_date: event.report_date, timing: event.timing, estimated_eps: event.estimated_eps }.freeze
      end

      def self.reported(asset)
        event = EarningsEvent.where(asset: asset, report_date: ..Date.current).reported.order(report_date: :desc).first
        event && { report_date: event.report_date, actual_eps: event.actual_eps, estimated_eps: event.estimated_eps }.freeze
      end
      private_class_method :upcoming, :reported
    end
  end
end
