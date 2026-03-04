module SparklineHelper
  # Returns normalized heights (0-100) from the last `points` of price history.
  # Falls back to nil if no history is available (sparkline uses direction-based bars).
  def sparkline_heights(asset, points: 7)
    closes = if asset.asset_price_histories.loaded?
               asset.asset_price_histories.sort_by(&:date).last(points).map(&:close)
    else
               asset.asset_price_histories.order(date: :desc).limit(points).pluck(:close).reverse
    end
    return nil if closes.size < 2

    min = closes.min
    max = closes.max
    range = max - min

    return closes.map { 50 } if range.zero?

    closes.map { |c| ((c - min) / range * 100).round.to_i }
  end
end
