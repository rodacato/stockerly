module MarketData
  module Domain
    # Entry levels stepped down from the current price by the asset's own daily
    # range, and one exit level trailing its recent high.
    #
    # The point is the unit. Buying at 190, 180 and 170 is three round numbers
    # borrowed from no asset in particular; buying at −1, −2 and −3 ATR is the
    # same decision scaled to how this one actually moves. Measured across the
    # assets on file that scale spans a factor of ten.
    module VolatilityLayers
      DEFAULT_COUNT = 3
      # One ATR between layers. The 3.0–4.0 band the literature gives for a
      # position-trading horizon describes a single stop distance, not the
      # spacing of a ladder — read as spacing it would put the third layer nine
      # ATR down, which is a different thesis wearing this one's name. It is
      # used below, where it belongs: on the trailing exit.
      DEFAULT_SPACING = 1.0
      # Chandelier Exit, Chuck LeBeau: the highest high of the last 22 sessions
      # less three ATR.
      TRAILING_MULTIPLE = 3.0
      TRAILING_LOOKBACK = 22

      Layer = Data.define(:step, :price, :atr_distance)

      module_function

      # Entry levels, nearest first. Empty rather than a ladder at zero spacing
      # when there is no ATR to space it by — a level nobody can defend is worse
      # than no level.
      def entries(price:, atr:, count: DEFAULT_COUNT, spacing: DEFAULT_SPACING)
        return [] unless usable?(price, atr)

        (1..count).filter_map do |step|
          distance = step * spacing
          level = price - (distance * atr)
          next unless level.positive?

          Layer.new(step: step, price: level.round(2), atr_distance: distance)
        end
      end

      # An exit that trails the high is not the mirror of an entry that steps
      # down from spot, so this is one level and not an inverted ladder.
      def trailing_exit(highest_high:, atr:, multiple: TRAILING_MULTIPLE)
        return nil unless usable?(highest_high, atr)

        level = highest_high - (multiple * atr)
        return nil unless level.positive?

        Layer.new(step: 1, price: level.round(2), atr_distance: multiple)
      end

      def usable?(price, atr)
        price.present? && atr.present? && price.positive? && atr.positive?
      end
    end
  end
end
