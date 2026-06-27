module EarningsHelper
  WEEKDAY_LABELS = {
    "DOM" => "Domingo", "LUN" => "Lunes", "MAR" => "Martes", "MIÉ" => "Miércoles",
    "JUE" => "Jueves",  "VIE" => "Viernes", "SÁB" => "Sábado"
  }.freeze

  def earnings_date_header(date)
    abbr  = DatetimeEsHelper::WEEKDAYS_ES[date.wday]
    month = DatetimeEsHelper::MONTHS_ES[date.month - 1]
    "#{WEEKDAY_LABELS[abbr]} · #{date.day} #{month} #{date.year}"
  end

  def earnings_period_label(event)
    quarter = ((event.report_date.month - 1) / 3) + 1
    year    = event.report_date.year.to_s[-2..]
    "#{quarter}T#{year}"
  end

  def earnings_timing_label(event)
    case event.timing
    when "before_market_open" then "pre-apertura"
    when "after_market_close" then "cierre de mercado"
    else "horario por confirmar"
    end
  end

  def earnings_status_label(event)
    event.actual_eps.present? ? "Reportado" : "Por reportar"
  end

  def earnings_status_classes(event)
    if event.actual_eps.present?
      "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-700 dark:text-emerald-400"
    else
      "bg-slate-100 dark:bg-slate-700 text-slate-500 dark:text-slate-400"
    end
  end

  def earnings_currency(event)
    event.asset.currency.presence || (event.asset.exchange == "BMV" ? "MXN" : "USD")
  end

  def earnings_venue(event)
    event.asset.exchange.presence || "—"
  end

  def earnings_delta_classes(percent)
    return "text-slate-500 dark:text-slate-400" if percent.nil?
    percent >= 0 ? "text-emerald-600 dark:text-emerald-400" : "text-rose-600 dark:text-rose-400"
  end

  def earnings_period_options
    [
      [ "Esta semana",    "semana" ],
      [ "Este mes",       "mes" ],
      [ "Este trimestre", "trimestre" ]
    ]
  end

  def earnings_market_options
    [
      [ "Todos",  "todos" ],
      [ "BMV",    "BMV" ],
      [ "NASDAQ", "NASDAQ" ],
      [ "NYSE",   "NYSE" ]
    ]
  end
end
