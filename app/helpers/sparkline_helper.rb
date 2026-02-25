module SparklineHelper
  # Returns normalized heights (0-100) from the last `days` of price history.
  # Falls back to nil if no history is available (sparkline uses direction-based bars).
  def sparkline_heights(asset, days: 7)
    cutoff = days.days.ago.to_date
    closes = if asset.asset_price_histories.loaded?
               asset.asset_price_histories.select { |h| h.date >= cutoff }.sort_by(&:date).map(&:close)
    else
               asset.asset_price_histories.recent(days).pluck(:close)
    end
    return nil if closes.size < 2

    min = closes.min
    max = closes.max
    range = max - min

    return closes.map { 50 } if range.zero?

    closes.map { |c| ((c - min) / range * 100).round.to_i }
  end
end
