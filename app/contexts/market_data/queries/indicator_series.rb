module MarketData
  module Queries
    # RSI and Bollinger as they stood on each date of a window, recomputed from
    # the stored closes. `technical_readings` holds one row per asset and
    # overwrites it daily, so a chart cannot read history out of it — the same
    # gap `RsiOnDates` fills for a single date, widened to a series.
    #
    # It is a read API in the ADR-002 sense: Trading may call it.
    class IndicatorSeries
      # @api public
      def self.call(asset:, from: nil)
        closes = PriceSeries.for(asset).closes_by_date
        return {} if closes.empty?

        dates, values = closes.keys, closes.values
        bands = Domain::TechnicalIndicators.bollinger_series(values)

        {
          rsi: series(dates, Domain::TechnicalIndicators.rsi_series(values), from) { |value| value },
          bb_upper: series(dates, bands, from) { |band| band[:upper] },
          bb_lower: series(dates, bands, from) { |band| band[:lower] }
        }
      end

      # Computed over the whole series and sliced afterwards, never computed
      # from the window's own first close. Wilder's RSI is path-dependent, so a
      # window that seeds itself at the visible edge draws a line that disagrees
      # with the number the Señales card prints from the same closes.
      def self.series(dates, values, from)
        dates.each_with_index.filter_map do |date, index|
          value = values[index]
          next if value.nil? || (from && date < from)

          { time: date.to_s, value: yield(value) }
        end
      end
      private_class_method :series
    end
  end
end
