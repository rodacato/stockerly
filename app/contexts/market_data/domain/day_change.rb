module MarketData
  module Domain
    # The one definition of the day change every screen renders:
    # (current close − previous close) / previous close, as a percentage.
    #
    # ADR-021: `assets.change_percent_24h` used to carry whichever measure the
    # provider that answered happened to ship, so it could not be what a screen
    # read. The column is gone; computing from two closes is
    # provider-independent, and RecordPriceHistory keeps today's row at the
    # current price, so the figure moves with the sync instead of going stale
    # at the close.
    #
    # "Previous" is the previous row, never yesterday's date: equities do not
    # trade every day and crypto does.
    class DayChange
      # @api public — read by Alerts (ADR-002 read API)
      # nil when there is no previous close to compare against — a newly
      # tracked asset has no day change, which is not the same as no movement.
      def self.from_closes(closes)
        current, previous = Array(closes).last(2).reverse
        return nil if current.nil? || previous.nil?

        previous = previous.to_d
        return nil if previous.zero?

        (current.to_d - previous) / previous * 100
      end

      # {asset_id => [closes, oldest first]} → {asset_id => percent or nil}.
      def self.by_asset(closes_by_asset)
        closes_by_asset.to_h { |asset_id, closes| [ asset_id, from_closes(closes) ] }
      end
    end
  end
end
