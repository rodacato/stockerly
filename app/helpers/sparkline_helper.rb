module SparklineHelper
  # Normalized 0-100 heights from a series of closes, oldest first. Fewer than
  # two points has no shape to draw, so the sparkline falls back to its
  # direction-only bars.
  #
  # Coerced to float because integer closes would divide to a flat line: this
  # worked only as long as every caller happened to pass BigDecimal.
  def sparkline_heights(closes)
    closes = Array(closes).map(&:to_f)
    return nil if closes.size < 2

    min, max = closes.minmax
    range = max - min
    return closes.map { 50 } if range.zero?

    closes.map { |close| ((close - min) / range * 100).round.to_i }
  end
end
