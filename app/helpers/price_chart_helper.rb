module PriceChartHelper
  # Generates SVG polyline points and area fill points from price history data.
  # Returns nil if insufficient data (< 2 points).
  #
  # Returns a Hash:
  #   { points: "x,y x,y ...", area: "x,y x,y ...", color: "#hex",
  #     min_price: Float, max_price: Float, first_date: Date, last_date: Date }
  def price_chart_data(price_histories, width: 500, height: 160)
    return nil if price_histories.size < 2

    closes = price_histories.map(&:close).map(&:to_f)
    dates = price_histories.map(&:date)

    min_price = closes.min
    max_price = closes.max
    range = max_price - min_price
    range = 1.0 if range.zero?

    padding = 4
    chart_height = height - (padding * 2)
    step_x = width.to_f / (closes.size - 1)

    coords = closes.each_with_index.map do |close, i|
      x = (i * step_x).round(1)
      y = (padding + chart_height - ((close - min_price) / range * chart_height)).round(1)
      [ x, y ]
    end

    polyline_pts = coords.map { |x, y| "#{x},#{y}" }.join(" ")

    # Area: polyline + bottom-right + bottom-left to close the shape
    area_pts = polyline_pts + " #{width},#{height} 0,#{height}"

    # Color: green if price went up, red if down
    trend_up = closes.last >= closes.first
    line_color = trend_up ? "#10b981" : "#ef4444"
    fill_color = trend_up ? "#10b981" : "#ef4444"

    data_points = coords.each_with_index.map do |coord, i|
      { cx: coord[0], cy: coord[1], date: dates[i], value: closes[i] }
    end

    volume_bars = build_volume_bars(price_histories, width, height, step_x)

    {
      points: polyline_pts,
      area: area_pts,
      color: line_color,
      fill_color: fill_color,
      min_price: min_price,
      max_price: max_price,
      first_date: dates.first,
      last_date: dates.last,
      data_points: data_points,
      volume_bars: volume_bars
    }
  end

  private

  def build_volume_bars(price_histories, width, height, step_x)
    volumes = price_histories.map { |ph| ph.respond_to?(:volume) ? ph.volume.to_i : 0 }
    max_volume = volumes.max || 0
    return [] if max_volume.zero?

    max_bar_height = height * 0.3
    bar_width = [ step_x * 0.6, 8 ].min

    volumes.each_with_index.map do |vol, i|
      bar_h = (vol.to_f / max_volume * max_bar_height).round(1)
      x = (i * step_x - bar_width / 2).round(1)
      y = (height - bar_h).round(1)
      { x: x, y: y, width: bar_width.round(1), height: bar_h, volume: vol }
    end
  end
end
