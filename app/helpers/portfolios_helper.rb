module PortfoliosHelper
  CHART_COLORS = (1..8).map { |n| "var(--color-chart-#{n})" }.freeze

  # Allocation hash → donut segments. Extracted from the pre-2.0 sidebar, which
  # built this inline in the template it shared with the sector breakdown.
  def allocation_segments(allocation)
    segments_for(allocation) { |asset_type| t("comun.tipo_activo.#{asset_type}", default: asset_type.to_s.titleize) }
  end

  # Largest first; what does not fit the palette is folded into "Otros" so two
  # segments never share a colour. Yahoo's names are translated; one the table
  # does not know shows as given.
  def sector_segments(allocation)
    ranked = allocation.group_by { |sector, _| sector.is_a?(Symbol) ? sector : sector.presence }.transform_values { |rows| rows.sum { |_, value| value } }
                       .sort_by { |_, value| -value }
    if ranked.size > CHART_COLORS.size
      rest = ranked.drop(CHART_COLORS.size - 1)
      ranked = ranked.first(CHART_COLORS.size - 1) + [ [ :otros, rest.sum { |_, value| value } ] ]
    end

    segments_for(ranked.to_h) { |sector| sector_label(sector) }
  end

  def sector_label(sector)
    return t("portfolios.show.sector.sin_sector") if sector.nil?
    return t("portfolios.show.sector.otros") if sector == :otros
    return t("comun.tipo_activo.#{sector}") if sector.is_a?(Symbol)

    t("comun.sector.#{sector.parameterize(separator: '_')}", default: sector)
  end

  def segments_for(allocation)
    total = allocation.values.sum.to_f
    return [] unless total.positive?

    allocation.map.with_index do |(key, value), index|
      {
        label: yield(key),
        pct: (value / total * 100).round,
        color: CHART_COLORS[index % CHART_COLORS.length],
        value: value
      }
    end
  end

  # Two lines for the chart controller: what the patrimony was worth, and the
  # initial valuation plus net contributions. lightweight-charts wants ISO dates as `time`.
  def chart_series_json(series)
    [
      { data: series.map { |point| { time: point[:date].to_s, value: point[:value] } },
        token: "--color-positive-fg", width: 2 },
      { data: series.map { |point| { time: point[:date].to_s, value: point[:contributed] } },
        token: "--color-fg-subtle", width: 2 }
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
