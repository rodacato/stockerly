module PortfolioChartHelper
  def portfolio_chart_data(data_points, width: 500, height: 160)
    return nil if data_points.size < 2

    values = data_points.map { |d| d[:value] }
    dates = data_points.map { |d| d[:date] }

    min_val = values.min
    max_val = values.max
    range = max_val - min_val
    range = 1.0 if range.zero?

    padding = 4
    chart_height = height - (padding * 2)
    step_x = width.to_f / (values.size - 1)

    coords = values.each_with_index.map do |val, i|
      x = (i * step_x).round(1)
      y = (padding + chart_height - ((val - min_val) / range * chart_height)).round(1)
      [ x, y ]
    end

    polyline_pts = coords.map { |x, y| "#{x},#{y}" }.join(" ")
    area_pts = polyline_pts + " #{width},#{height} 0,#{height}"

    trend_up = values.last >= values.first
    line_color = trend_up ? "#10b981" : "#ef4444"

    data_points = coords.each_with_index.map do |coord, i|
      { cx: coord[0], cy: coord[1], date: dates[i], value: values[i] }
    end

    {
      points: polyline_pts,
      area: area_pts,
      color: line_color,
      min_value: min_val,
      max_value: max_val,
      first_date: dates.first,
      last_date: dates.last,
      data_points: data_points
    }
  end
end
