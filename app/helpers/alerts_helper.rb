module AlertsHelper
  # User-facing es-MX label for AlertRule#condition. Matches the mockup
  # chip names exactly so the form, the rules table, and the live feed
  # speak the same vocabulary.
  CONDITION_LABELS = {
    "price_crosses_above" => "Precio cruza umbral",
    "price_crosses_below" => "Precio cruza umbral",
    "day_change_percent"  => "% cambio en el día",
    "rsi_overbought"      => "RSI sobrecomprado",
    "rsi_oversold"        => "RSI sobrevendido",
    "volume_spike"        => "Volumen anómalo",
    "dividend_ex_date"    => "Dividendo próximo",
    "bmv_holiday"         => "BMV festivo",
    "cete_auction"        => "Subasta CETES"
  }.freeze

  # Live-feed accent dot color per AlertRule#condition. Drives off the
  # rule's condition (not the localized message text) so the mapping
  # survives copy edits and locale changes.
  CONDITION_ACCENTS = {
    "price_crosses_above" => "bg-emerald-500",
    "price_crosses_below" => "bg-rose-500",
    "day_change_percent"  => "bg-amber-500",
    "rsi_overbought"      => "bg-amber-500",
    "rsi_oversold"        => "bg-amber-500",
    "volume_spike"        => "bg-amber-500",
    "dividend_ex_date"    => "bg-primary",
    "bmv_holiday"         => "bg-primary",
    "cete_auction"        => "bg-primary"
  }.freeze

  # Kind chip shown next to the ticker (per mockup: "Acción", "Mercado",
  # "Fondo", "CETE"). We derive it from the symbol because we don't have a
  # downstream Asset record for every alert rule (rules can outlive assets).
  def alert_rule_kind_label(rule)
    return "BMV"   if rule.condition == "bmv_holiday"
    return "CETES" if rule.condition == "cete_auction"

    case rule.asset_symbol
    when /\ACETES?_/i, /\ACETE\b/i then "CETE"
    when /\.MX\z/i                 then "Acción MX"
    when "BMV", "IPC", /\AIPC\b/i  then "Mercado"
    else                                "Acción"
    end
  end

  def alert_condition_label(rule)
    CONDITION_LABELS.fetch(rule.condition, rule.condition.to_s.humanize)
  end

  # Descriptive es-MX summary that mirrors the "preview" line in the create
  # form and the "Condición" column of the rules table. ADR-0001: describes
  # the trigger, never tells the user what to do.
  def alert_condition_summary(rule)
    case rule.condition
    when "price_crosses_above"
      "cruza #{rule.currency} #{format_threshold(rule.threshold_value)} al alza"
    when "price_crosses_below"
      "cruza #{rule.currency} #{format_threshold(rule.threshold_value)} a la baja"
    when "day_change_percent"
      "se mueve más de #{format_threshold(rule.threshold_value)}% en el día"
    when "rsi_overbought"
      "RSI(14) ≥ #{rule.threshold_value.to_i}"
    when "rsi_oversold"
      "RSI(14) ≤ #{rule.threshold_value.to_i}"
    when "volume_spike"
      "volumen > #{format_threshold(rule.threshold_value)}× promedio 30d"
    when "dividend_ex_date"
      "#{rule.window_days.to_i} día(s) antes del ex-date"
    when "bmv_holiday"
      "#{rule.window_days.to_i} día(s) antes de un festivo BMV"
    when "cete_auction"
      "#{rule.window_days.to_i} día(s) antes de una subasta Banxico"
    else
      rule.condition.to_s.humanize
    end
  end

  def format_threshold(value)
    BigDecimal(value.to_s).to_s("F").sub(/\.?0+\z/, "")
  end

  # Lightweight relative-time string in es-MX. The live feed uses it to
  # mirror the mockup's "hoy · 14:42 CDMX" tone.
  def alert_event_when(event)
    t = event.triggered_at
    date = t.to_date
    cdmx_time = t.in_time_zone("America/Mexico_City").strftime("%H:%M")

    if date == Date.current
      "hoy · #{cdmx_time} CDMX"
    elsif date == Date.current - 1
      "ayer · #{cdmx_time} CDMX"
    else
      "#{date.day} #{NotificationsHelper::MONTHS[date.month - 1]} · #{cdmx_time} CDMX"
    end
  end

  def alert_event_accent(event)
    rule = event.alert_rule
    return "bg-primary" unless rule

    CONDITION_ACCENTS.fetch(rule.condition, "bg-primary")
  end

  # Conditions offered in the create form, in display order. Derives labels
  # from CONDITION_LABELS so the copy lives in one place (the form, the rules
  # table, and the live feed stay in sync).
  CONDITION_OPTION_ORDER = %w[
    price_crosses_above rsi_oversold rsi_overbought
    volume_spike dividend_ex_date bmv_holiday cete_auction
  ].freeze

  def alert_condition_options
    CONDITION_OPTION_ORDER.map { |condition| [ condition, CONDITION_LABELS.fetch(condition) ] }
  end

  # Conditions that need a "Dirección" (al alza / a la baja) segmented
  # control. Used by the form preview line.
  def alert_directional?(condition)
    %w[price_crosses_above price_crosses_below].include?(condition.to_s)
  end
end
