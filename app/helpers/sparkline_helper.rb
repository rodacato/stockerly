module SparklineHelper
  # Returns normalized heights (0-100) from the last `points` of price history.
  # Falls back to nil if no history is available (sparkline uses direction-based bars).
  def sparkline_heights(asset, points: 7)
    closes = MarketData::Queries::PriceSeries.for(asset).latest(points).map(&:close)
    return nil if closes.size < 2

    min = closes.min
    max = closes.max
    range = max - min

    return closes.map { 50 } if range.zero?

    closes.map { |c| ((c - min) / range * 100).round.to_i }
  end
end
