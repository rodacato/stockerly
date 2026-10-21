module MarketData
  module Domain
    # The conventional reading of the VIX, the market's own estimate of how much
    # the S&P 500 will swing over the next 30 days. The bands are the usual
    # rules of thumb, not a statistical finding, and say so in the `?`.
    class VolatilityLevel
      BANDS = { calm: 0...15, normal: 15...25, elevated: 25...35 }.freeze

      def self.for(value)
        BANDS.find { |_, range| range.cover?(value) }&.first || :high
      end
    end
  end
end
