module AlertsHelper
  # What the rule watches. A marketwide rule stores no symbol, so it names the
  # market itself rather than drawing the dash the app uses for "we don't know".
  def alert_rule_scope_label(rule)
    rule.marketwide? ? alert_rule_kind_label(rule) : rule.asset_symbol
  end

  # Kind chip shown next to the ticker. Only the asset decides it; a symbol the
  # catalogue does not list gets no chip rather than a guess.
  def alert_rule_kind_label(rule)
    return "BMV"   if rule.condition == "bmv_holiday"
    return "CETES" if rule.condition == "cete_auction"

    asset = alert_rule_asset(rule.asset_symbol)
    kind_label_for(asset) if asset
  end

  # nil unless the rule watches a symbol the catalogue no longer lists under
  # that name. Marketwide rules watch no symbol.
  def alert_rule_orphan(rule)
    return if rule.marketwide? || rule.asset_symbol.blank?

    @alert_rule_listings ||= {}
    listing = (@alert_rule_listings[rule.asset_symbol] ||= Alerts::Queries::SymbolListing.call(symbol: rule.asset_symbol))
    listing unless listing[:state] == :listed
  end

  def alert_orphan_label(rule, orphan)
    if orphan[:state] == :renamed
      t("alerts.index.huerfana.renombrada", old: rule.asset_symbol, symbol: orphan[:current_symbol])
    else
      t("alerts.index.huerfana.ausente", symbol: rule.asset_symbol)
    end
  end

  def alert_condition_label(rule)
    condition_label(rule.condition)
  end

  # Descriptive es-MX summary that mirrors the "preview" line in the create
  # form and the "Condición" column of the rules table. ADR-0001: describes
  # the trigger, never tells the user what to do.
  def alert_condition_summary(rule)
    case rule.condition
    when "price_crosses_above", "price_crosses_below"
      t("alerts.condiciones.#{rule.condition}.resumen", currency: rule.currency, threshold: format_threshold(rule.threshold_value)).squish
    when "day_change_percent"
      t("alerts.condiciones.day_change_percent.resumen", threshold: format_threshold(rule.threshold_value))
    when "rsi_overbought"
      t("alerts.condiciones.rsi_overbought.resumen", threshold: rule.threshold_value.to_i)
    when "rsi_oversold"
      t("alerts.condiciones.rsi_oversold.resumen", threshold: rule.threshold_value.to_i)
    when "volume_spike"
      t("alerts.condiciones.volume_spike.resumen", threshold: format_threshold(rule.threshold_value),
                                                   days: Alerts::Domain::AlertEvaluator::VOLUME_AVERAGE_DAYS)
    when "dividend_ex_date"
      t("alerts.condiciones.dividend_ex_date.resumen", count: rule.window_days.to_i)
    when "bmv_holiday"
      t("alerts.condiciones.bmv_holiday.resumen", count: rule.window_days.to_i)
    when "cete_auction"
      t("alerts.condiciones.cete_auction.resumen", count: rule.window_days.to_i)
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
      "#{l(date, format: :day_month_upper)} · #{cdmx_time} CDMX"
    end
  end

  # Conditions offered in the create form, in display order. Derives labels
  # from the same locale tree as the rules table and the live feed, so the
  # three speak one vocabulary.
  # Grouped the way `reglas-nueva-regla` draws them. `price_crosses_below` and
  # `day_change_percent` were absent from the old flat list while the
  # evaluator, the contract and TriggerNotice all handled them — two of the
  # nine conditions were built and simply never offered. `below` is not a chip
  # of its own: it shares "Precio cruza umbral" and the direction control picks
  # the enum value, which is what the artboard draws.
  CONDITION_FAMILIES = {
    precio:    %w[price_crosses_above day_change_percent],
    senal:     %w[rsi_overbought rsi_oversold volume_spike],
    calendario: %w[dividend_ex_date cete_auction bmv_holiday]
  }.freeze

  DIRECTIONAL_CONDITIONS = %w[price_crosses_above price_crosses_below].freeze

  def alert_condition_families
    CONDITION_FAMILIES.transform_values do |conditions|
      conditions.map { |condition| [ condition, condition_label(condition) ] }
    end
  end

  def alert_condition_options
    CONDITION_FAMILIES.values.flatten.map { |condition| [ condition, condition_label(condition) ] }
  end

  # "espera 60 min entre avisos" — the artboard surfaces the cooldown the
  # model has carried since it was created and no screen ever showed.
  def alert_cooldown_label(rule)
    t("alerts.index.espera", minutes: rule.cooldown_minutes || AlertRule::DEFAULT_COOLDOWN_MINUTES)
  end

  # "Se revisa con cada precio nuevo, hasta cada 5 min" — nil when the schedule
  # holds nothing to say it from.
  def alert_check_cadence_label(rule)
    cadence = Alerts::Domain::CheckCadence.for(rule)

    case cadence
    in { kind: :daily, time: String => time } then t("alerts.index.revision_diaria", time: time)
    in { kind: :price_update, minutes: Integer => minutes } then t("alerts.index.revision_precio", minutes: minutes)
    else nil
    end
  end

  # What the rule's indicator means, from the copy the empty-state suggestions
  # already carry. Only some conditions have it; the rest return nil.
  def alert_rule_explainer(rule)
    return unless I18n.exists?("alerts.index.sugerencias.#{rule.condition}.porque")

    condition_explainer(rule.condition, rule)
  end

  private

  def condition_explainer(condition, shape)
    t("alerts.index.sugerencias.#{condition}.porque",
      percent: (format_threshold(shape.threshold_value) if shape.threshold_value.present?),
      threshold: shape.threshold_value.to_i,
      days: shape.window_days.to_i)
  end

  def condition_label(condition)
    t("alerts.condiciones.#{condition}.etiqueta", default: condition.to_s.humanize)
  end

  # Memoized per request: the rules table calls this once per row, and a
  # handful of rules share very few distinct symbols.
  def alert_rule_asset(symbol)
    return nil if symbol.blank?

    @alert_rule_assets ||= {}
    return @alert_rule_assets[symbol] if @alert_rule_assets.key?(symbol)

    @alert_rule_assets[symbol] = Asset.find_by(symbol: symbol)
  end

  def kind_label_for(asset)
    label = asset_type_label_es(asset.asset_type)
    asset.asset_type_stock? && asset.symbol.to_s.match?(/\.MX\z/i) ? "#{label} MX" : label
  end

  # A suggestion carries the shape of a rule, never its wording (ALR-2), so the
  # three phrases are assembled here against one key per condition.
  def suggested_rule_title(suggestion)
    t("alerts.index.sugerencias.#{suggestion.condition}.titulo",
      symbol: suggestion.asset_symbol,
      percent: suggested_percent(suggestion))
  end

  def suggested_rule_reason(suggestion)
    condition_explainer(suggestion.condition, suggestion)
  end

  # count picks the plural form, amount is what gets read: a fractional crypto
  # holding must not round to "0 títulos" just to satisfy pluralization.
  def suggested_rule_context(suggestion)
    return if suggestion.shares.blank?

    t("alerts.index.sugerencias.contexto",
      count: suggestion.shares.to_i,
      amount: format_threshold(suggestion.shares))
  end

  def suggested_percent(suggestion)
    format_threshold(suggestion.threshold_value) if suggestion.threshold_value.present?
  end

  def suggested_rule_path(suggestion)
    new_alert_path(asset_symbol: suggestion.asset_symbol,
                   condition: suggestion.condition,
                   threshold_value: suggestion.threshold_value,
                   window_days: suggestion.window_days)
  end
end
