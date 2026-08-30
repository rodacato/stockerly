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

      # The last `points` closes for many assets in ONE statement, oldest first.
      #
      # The obvious alternative — preloading :asset_price_histories — was built,
      # measured and reverted (X15): it loads the whole series to draw seven
      # points, and that cost grows with the table while a per-row query's does
      # not. Rails cannot limit a preloaded has_many, so the window function is
      # the only shape that beats both.
      def self.recent_closes(assets, points: 7, interval: DAILY)
        ids = Array(assets).map { |asset| asset.try(:id) || asset }.uniq
        return {} if ids.empty?

        ranked = AssetPriceHistory
                   .select("asset_id, close, date, ROW_NUMBER() OVER (PARTITION BY asset_id ORDER BY date DESC) AS rn")
                   .where(asset_id: ids, interval: interval)

        AssetPriceHistory.from(ranked, :asset_price_histories)
                         .where("rn <= ?", points)
                         .order(:asset_id, :date)
                         .pluck(:asset_id, :close)
                         .group_by(&:first)
                         .transform_values { |rows| rows.map(&:last) }
      end

      # Volumes from rows already in hand, minus today's. A running total would
      # drag the 5-day leg of a volume trend down by however early it is read.
      def self.closed_volumes(rows)
        rows.reject { |row| row.date >= Date.current }.map(&:volume)
      end

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

      # Bars whose day is over. Today's row is still accumulating — high, low
      # and volume grow with every sync — so anything reading those stops here.
      def closed
        scope.where(date: ...Date.current).order(:date)
      end

      def average_volume(days)
        closed.where(date: days.days.ago.to_date..).average(:volume)&.to_i || 0
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
