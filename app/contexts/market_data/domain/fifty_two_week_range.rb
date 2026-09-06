module MarketData
  module Domain
    # Where the current price sits between the year's low and high.
    #
    # No zone thresholds: which bound is reported is decided by which one is
    # nearer, and the distance to it is a fact rather than a judgement — D36
    # rules out a chip whose threshold cannot be written down and defended.
    #
    # The stored bounds come from a provider that refreshes on its own cadence,
    # so a price outside them is normal and says something real: the asset is
    # making a high the metric has not caught up with.
    class FiftyTwoWeekRange
      Reading = Data.define(:low, :high, :price, :position, :zone, :distance) do
        # Where any other price sits on the same track. Clamped like `position`,
        # so a cost older than the year's low still lands on the bar.
        def position_of(other)
          return nil if other.blank?

          ((other.to_d - low) / (high - low)).clamp(0, 1)
        end
      end

      def self.for(price:, low:, high:)
        return nil if price.blank? || low.blank? || high.blank?

        low, high, price = low.to_d, high.to_d, price.to_d
        return nil unless high > low

        zone, bound = classify(price, low, high)

        Reading.new(low: low, high: high, price: price,
                    position: ((price - low) / (high - low)).clamp(0, 1),
                    zone: zone, distance: ((price - bound).abs / bound * 100).round(1))
      end

      def self.classify(price, low, high)
        return [ :above_high, high ] if price > high
        return [ :below_low, low ]   if price < low

        (price - low) >= (high - price) ? [ :high, high ] : [ :low, low ]
      end
      private_class_method :classify
    end
  end
end
