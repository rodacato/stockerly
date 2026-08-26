module MarketData
  module Queries
    # The single place daily price history is read from.
    #
    # ADR-016 stores one row per (asset, date, interval) today and keeps the
    # multi-source shape reachable — one row per (asset, date, interval,
    # source), which needs a resolution policy on every read. That policy has a
    # home only if the reads have one: scattered across the call sites, those
    # call sites *are* the migration.
    #
    # It is a read API in the ADR-002 sense: Trading may call it.
    class PriceSeries
      DAILY = "1d".freeze

      def self.for(asset, interval: DAILY) = new(asset, interval: interval)

      def initialize(asset, interval: DAILY)
        @asset = asset
        @interval = interval
      end

      # Every row, oldest first.
      def all
        scope.order(:date)
      end

      def recent(days)
        since(days.days.ago.to_date)
      end

      def since(date)
        scope.where(date: date..).order(:date)
      end

      def between(from, to)
        scope.where(date: from..to).order(:date)
      end

      # The last `count` rows in chronological order. Uses the association when
      # it is already loaded, so an eager-loaded detail page does not re-query.
      def latest(count)
        return loaded_rows.last(count) if loaded?

        scope.order(date: :desc).limit(count).to_a.reverse
      end

      def closes_by_date
        return loaded_rows.to_h { |row| [ row.date, row.close ] } if loaded?

        scope.order(:date).pluck(:date, :close).to_h
      end

      def average_volume(days)
        scope.where(date: days.days.ago.to_date..).average(:volume)&.to_i || 0
      end

      private

      attr_reader :asset, :interval

      def scope
        asset.asset_price_histories.where(interval: interval)
      end

      def loaded?
        interval == DAILY && asset.asset_price_histories.loaded?
      end

      def loaded_rows
        asset.asset_price_histories.select { |row| row.interval == interval }.sort_by(&:date)
      end
    end
  end
end
