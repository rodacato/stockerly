module PortfoliosHelper
  CHART_COLORS = (1..8).map { |n| "var(--color-chart-#{n})" }.freeze

  # Allocation hash → donut segments. Extracted from the pre-2.0 sidebar, which
  # built this inline in the template it shared with the sector breakdown.
  def allocation_segments(allocation)
    total = allocation.values.sum.to_f
    return [] unless total.positive?

    allocation.map.with_index do |(asset_type, value), index|
      {
        label: t("comun.tipo_activo.#{asset_type}", default: asset_type.to_s.titleize),
        pct: (value / total * 100).round,
        color: CHART_COLORS[index % CHART_COLORS.length],
        value: value
      }
    end
  end

  # Two lines for the chart controller: what the patrimony was worth, and the
  # capital put into it. lightweight-charts wants ISO dates as `time`.
  def chart_series_json(series)
    [
      { data: series.map { |point| { time: point[:date].to_s, value: point[:value] } },
        token: "--color-positive", width: 2 },
      { data: series.map { |point| { time: point[:date].to_s, value: point[:contributed] } },
        token: "--color-border-strong", width: 2 }
    ].to_json
  end

  # "1M" reads as a period; "m1" is what an I18n key can hold.
  def period_key(period)
    case period
    when "YTD" then "ytd"
    when "MAX" then "max"
    else period.sub(/\A(\d+)([MA])\z/) { "#{Regexp.last_match(2).downcase.tr("a", "y")}#{Regexp.last_match(1)}" }
    end
  end
end
