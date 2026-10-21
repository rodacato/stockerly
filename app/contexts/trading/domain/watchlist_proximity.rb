module Trading
  module Domain
    # How far each watched asset sits from its nearest price threshold, as a
    # percentage because D10 leaves watchlist prices unconverted. Keyed by
    # symbol; an asset with no usable threshold or price has no entry.
    class WatchlistProximity
      def self.gaps(user)
        thresholds = thresholds_by_symbol(user)

        user.watchlist_items.includes(:asset).each_with_object({}) do |item, gaps|
          distance = nearest_distance(item.asset.current_price, thresholds[item.asset.symbol])
          gaps[item.asset.symbol] = distance if distance
        end
      end

      def self.thresholds_by_symbol(user)
        user.alert_rules
            .active
            .where(condition: AlertRule::PRICE_THRESHOLD_CONDITIONS)
            .where.not(threshold_value: nil)
            .pluck(:asset_symbol, :threshold_value)
            .group_by(&:first)
            .transform_values { |rows| rows.map(&:last) }
      end

      def self.nearest_distance(price, thresholds)
        return nil if price.blank? || price.zero? || thresholds.blank?

        thresholds.map { |threshold| ((threshold - price) / price * 100).abs }.min
      end

      private_class_method :thresholds_by_symbol, :nearest_distance
    end
  end
end
