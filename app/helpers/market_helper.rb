module MarketHelper
  # Returns the visual configuration for the VIX volatility indicator
  # based on the current value. Static class triplets so Tailwind's JIT
  # compiler can see the full class names at build time (no dynamic
  # `text-<color>-600` interpolation).
  def vix_tier(value)
    case value.to_f
    when 0...20
      { icon: "text-emerald-500",
        value: "text-emerald-600 dark:text-emerald-400",
        pill:  "text-emerald-600 dark:text-emerald-400 bg-emerald-50 dark:bg-emerald-900/30",
        label: "Volatilidad baja" }
    when 20...30
      { icon: "text-amber-500",
        value: "text-amber-600 dark:text-amber-400",
        pill:  "text-amber-600 dark:text-amber-400 bg-amber-50 dark:bg-amber-900/30",
        label: "Volatilidad moderada" }
    else
      { icon: "text-rose-500",
        value: "text-rose-600 dark:text-rose-400",
        pill:  "text-rose-600 dark:text-rose-400 bg-rose-50 dark:bg-rose-900/30",
        label: "Volatilidad alta" }
    end
  end

  # es-MX label for a trend score (0–100). Buckets match the visual
  # strength bar tiers in _listings_table (Fuerte → success bar,
  # Moderada → warning, Débil/Muy débil → error).
  def trend_strength_label(score)
    case score.to_i
    when 80..100 then "Fuerte"
    when 50..79  then "Moderada"
    when 25..49  then "Débil"
    else              "Muy débil"
    end
  end

  # Which source leads this asset's price chain, by name. The registry already
  # answers it, so the row cannot offer a provider that was never in the chain.
  def tracked_price_source(asset)
    DataSourceRegistry
      .for_capability(:prices, market: asset.market, asset_type: asset.asset_type)
      .first&.integration_name
  end

  # Native-currency price prefix used on the asset detail header and price
  # chart. Per ADR / S09 convention: "MXN 48.50" / "USD 612.85".
  def asset_currency_price(asset, precision: 2)
    format_currency_mx(asset.current_price, currency: asset.currency, precision: precision)
  end

  # The price in the reader's own currency, which is the whole MXN-first point:
  # a USD quote means little until you see what it is in pesos. Nil when the
  # asset already quotes in it, or when no rate is stored — an approximation
  # invented from a missing rate is worse than its absence.
  def approximate_in_preferred(asset, user)
    return nil if asset.current_price.blank? || asset.currency == user.preferred_currency

    rate = FxRateHistory.rate_on(base: asset.currency, quote: user.preferred_currency, date: Date.current) ||
           FxRate.find_by(base_currency: asset.currency, quote_currency: user.preferred_currency)&.rate
    return nil if rate.blank?

    format_currency_mx(asset.current_price * rate, currency: user.preferred_currency, precision: 0)
  end

  # The chart's range pills (CKP-2). Labels live in the locale keyed like
  # Consolidado's, so the two period controls read the same in es-MX.
  CHART_RANGE_KEYS = { "1S" => "s1", "1M" => "m1", "3M" => "m3", "1A" => "y1", "MAX" => "max" }.freeze

  def chart_range_options(asset, active)
    MarketData::UseCases::LoadAssetDetail::RANGES.keys.map do |key|
      [ t("market.precio.rango.#{CHART_RANGE_KEYS.fetch(key)}"),
        market_asset_path(asset.symbol, range: key),
        active == key ]
    end
  end

  # Volume is a share count, not money, so it does not go through
  # format_large_currency — a currency prefix on a number of shares is a lie.
  def format_compact_count(value)
    v = value.to_f
    if v.abs >= 1_000_000_000 then "#{number_with_precision(v / 1e9, precision: 1)}B"
    elsif v.abs >= 1_000_000  then "#{number_with_precision(v / 1e6, precision: 1)}M"
    elsif v.abs >= 1_000      then "#{number_with_precision(v / 1e3, precision: 1)}K"
    else number_with_delimiter(v.round)
    end
  end

  # D2 rejected a widget that loaded on every page load; D66 permits one behind
  # a click. Stocks and ETFs only: fixed income has no TradingView symbol, and
  # crypto needs an exchange prefix that `assets.exchange` does not always hold.
  # Both types are held to Asset::SYMBOL_FORMAT, so the shape is not re-derived.
  def tradingview_available?(asset)
    asset.asset_type_stock? || asset.asset_type_etf?
  end

  # Our own plot's height, and the embed's. TradingView draws a toolbar, a
  # legend and a MACD pane inside its box, so asking for a plot the size of ours
  # means asking for more than ours.
  CHART_HEIGHT = 260
  TRADINGVIEW_CHROME = 160
  TRADINGVIEW_HEIGHT = CHART_HEIGHT + TRADINGVIEW_CHROME
  TRADINGVIEW_ATTRIBUTION = 32

  # Travels to the browser as a Stimulus value, so ERB escapes it as an
  # attribute and nothing here is ever marked html_safe. `locale: "es"` and the
  # MACD id are both verified against the live widget, not assumed.
  #
  # `autosize` is off on purpose: it measures the container, the container lives
  # in a turbo frame that is empty until the click, and the widget was reading a
  # height the frame did not have yet. An explicit number cannot be mismeasured.
  def tradingview_config(asset)
    { symbol: asset.symbol, interval: "D", locale: "es", theme: "light",
      style: "1", autosize: false, width: "100%", height: TRADINGVIEW_HEIGHT,
      hide_side_toolbar: false, studies: [ "STD;MACD" ] }.to_json
  end

  # One series for the chart controller, from the closes we already sync.
  # Replaces the TradingView widget, which shipped the symbol being viewed to
  # a third party on every page load (D2).
  def price_series_json(histories)
    price_series(histories).to_json
  end

  def price_series(histories)
    [ { data: histories.map { |row| { time: row.date.to_s, value: row.close.to_f } },
        token: "--color-chart-1", width: 2 } ]
  end

  # The price plus whichever indicator layers this range carries (D101). A
  # series with a `layer` is one the legend can add and remove; the price has
  # none, because it is the chart.
  def asset_chart_series_json(histories, indicators)
    (price_series(histories) + indicator_layers(indicators)).to_json
  end

  # Tokens per the kit's 0.9.0 call: the bands and the RSI line reuse roles that
  # already exist rather than earning their own. RSI takes pane 1 — it is an
  # index between 0 and 100, and sharing the price scale would flatten both.
  #
  # D108: the pane says what it is and holds still. Left to autoscale it filled
  # itself with whatever the window happened to contain, so a quiet month and a
  # real oversold spike drew the same picture — and unlabelled under the price,
  # it read as more price chart. The thresholds are IndicatorSignals' own, so
  # the pane and the Señales row cannot disagree about what 70 means.
  def indicator_layers(indicators)
    return [] if indicators.blank?

    [ { data: indicators[:bb_upper], layer: "bollinger", token: "--color-border-strong", width: 1 },
      { data: indicators[:bb_lower], layer: "bollinger", token: "--color-border-strong", width: 1 },
      { data: indicators[:rsi], layer: "rsi", token: "--color-fg-default", width: 1, pane: 1,
        title: t("market.precio.rsi.titulo", period: MarketData::Domain::TechnicalIndicators::RSI_PERIOD),
        scale: { min: 0, max: 100 },
        guides: [ MarketData::Domain::IndicatorSignals::OVERBOUGHT,
                  MarketData::Domain::IndicatorSignals::OVERSOLD ] } ]
      .reject { |series| series[:data].blank? }
  end

  # Which checkboxes the legend has anything to offer for.
  def chart_layer_keys(layers, indicators)
    keys = layers.present? ? [ "levels" ] : []
    keys + indicator_layers(indicators).pluck(:layer).uniq
  end

  # The ATR levels as chart price lines. Each carries the card's own label, so
  # a line on the plot and a row in the card name the same level the same way.
  # The kind travels too: the trailing exit can land between two entry layers,
  # so its price does not say which it is.
  #
  # `holding` gates the exit for the reason the card gates it: an exit level for
  # something you do not own is a plan for a position that does not exist.
  # D106: the plot takes the short form of the card's label, not the card's own.
  # `lightweight-charts` butts the title against the axis price badge at the
  # right edge, so on a 318px plot the four full names covered ~40% of the
  # series — the most recent 40%, which is the part being read. `C1` still names
  # the level; the card two blocks down spells it out and prices it in ATR.
  def chart_levels_json(layers, holding: false)
    return "[]" if layers.blank?

    entries = layers[:entries].map do |layer|
      { price: layer.price.to_f, kind: "entry", label: t("market.layers.etiquetas_plot.entrada", n: layer.step) }
    end
    trailing = if holding && layers[:exit]
      [ { price: layers[:exit].price.to_f, kind: "exit", label: t("market.layers.etiquetas_plot.salida") } ]
    else
      []
    end

    (entries + trailing).to_json
  end

  # What the plot draws over the price without asking: your cost, when you hold
  # it. Not a layer — it has no checkbox because it is not an indicator, it is
  # the one line on the chart that is about you.
  #
  # D104: it now carries an axis label, because `lightweight-charts` draws a
  # price line's title ONLY alongside that label — with `axisLabelVisible` off
  # the title was computed, serialised, and thrown away, which left the bare
  # grey line D102 was opened to stop. The name goes on the line and the number
  # on the axis, the way a level does; the 52-week bar still spells the phrase.
  #
  # D107: absent, rather than drawn off-screen, when the cost falls outside what
  # the price did in this window. Price lines do not participate in autoscale,
  # so on a short range the line silently landed past the edge of the pane.
  def chart_anchors_json(cost, histories)
    return "[]" if cost.blank? || cost_outside_plot?(cost, histories)

    [ { price: cost.to_f, label: t("market.precio.anclas.costo") } ].to_json
  end

  # Measured against the closes alone, which is the one series every range
  # plots. Bollinger widens the scale when it is on, so judging by the visible
  # range would make the cost line appear and disappear with a checkbox — and
  # the honest statement is about the price window either way.
  def cost_outside_plot?(cost, histories)
    return false if cost.blank? || histories.blank?

    closes = histories.map { |row| row.close.to_f }
    cost.to_f < closes.min || cost.to_f > closes.max
  end

  # The three references the Análisis anchor reads against (CKP-8, D67). The
  # controller already loads all of them; nothing new is fetched here.
  # Used for technical observations in the asset detail page.
  # The numbers behind a Señales row, in the reading's own units: RSI is a
  # bare index, the other two are prices the phrase already named.
  def signal_value(signal)
    case signal[:indicator]
    when :rsi           then number_with_precision(signal[:value], precision: 1)
    when :moving_average then [ signal[:ma50], signal[:ma200] ].compact
                              .map { |v| number_with_precision(v, precision: 2, delimiter: ",") }.join(" · ")
    when :bollinger     then [ signal[:lower], signal[:upper] ]
                              .map { |v| number_with_precision(v, precision: 2, delimiter: ",") }.join(" – ")
    end
  end

  # Descriptive es-MX label for a technical observation, per ADR-001 —
  # purely observational, no action verbs. The asset symbol is rendered by
  # the caller so the phrase stays asset-agnostic. English keys remain the
  # canonical persisted observation_type; only the user-facing copy is es-MX.
  OBSERVATION_PHRASES = {
    "rsi_oversold_entered"   => "entró en zona de sobreventa (RSI(14) por debajo de 30)",
    "rsi_overbought_entered" => "entró en zona de sobrecompra (RSI(14) por encima de 70)",
    "rsi_oversold_exited"    => "salió de la zona de sobreventa",
    "rsi_overbought_exited"  => "salió de la zona de sobrecompra",
    "ma200_crossed_above"    => "cruzó al alza su MA200",
    "ma200_crossed_below"    => "cruzó a la baja su MA200",
    "ma50_crossed_above"     => "cruzó al alza su MA50",
    "ma50_crossed_below"     => "cruzó a la baja su MA50",
    "bb_upper_breached"      => "rompió la banda de Bollinger superior",
    "bb_lower_breached"      => "rompió la banda de Bollinger inferior"
  }.freeze

  # Short uppercase es-MX tag rendered next to the phrase in the asset
  # detail "Observaciones recientes" panel (S10 #93). One per indicator family.
  RSI_TAG = "RSI"
  MOVING_AVERAGE_TAG = "MEDIA MÓVIL"
  BOLLINGER_TAG = "BANDAS"
  OBSERVATION_TAGS = {
    "rsi_oversold_entered"   => RSI_TAG,
    "rsi_overbought_entered" => RSI_TAG,
    "rsi_oversold_exited"    => RSI_TAG,
    "rsi_overbought_exited"  => RSI_TAG,
    "ma200_crossed_above"    => MOVING_AVERAGE_TAG,
    "ma200_crossed_below"    => MOVING_AVERAGE_TAG,
    "ma50_crossed_above"     => MOVING_AVERAGE_TAG,
    "ma50_crossed_below"     => MOVING_AVERAGE_TAG,
    "bb_upper_breached"      => BOLLINGER_TAG,
    "bb_lower_breached"      => BOLLINGER_TAG
  }.freeze

  # Visual accent ("pos" green, "warn" amber, neutral primary) for the
  # observation dot. Bullish-leaning → pos; bearish/extreme → warn; rest →
  # neutral. Mapped to a CSS class by #observation_dot_class.
  OBSERVATION_ACCENTS = {
    "rsi_oversold_entered"   => "warn",
    "rsi_overbought_entered" => "warn",
    "rsi_oversold_exited"    => "pos",
    "rsi_overbought_exited"  => "neutral",
    "ma200_crossed_above"    => "pos",
    "ma200_crossed_below"    => "warn",
    "ma50_crossed_above"     => "pos",
    "ma50_crossed_below"     => "warn",
    "bb_upper_breached"      => "warn",
    "bb_lower_breached"      => "warn"
  }.freeze

  def observation_phrase(observation)
    type = observation.observation_type
    OBSERVATION_PHRASES.fetch(type, type.humanize)
  end

  def observation_tag(observation)
    OBSERVATION_TAGS.fetch(observation.observation_type, "SEÑAL")
  end

  def observation_accent(observation)
    OBSERVATION_ACCENTS.fetch(observation.observation_type, "neutral")
  end

  # es-MX accent → dot color class for the observation row.
  def observation_dot_class(accent)
    case accent
    when "pos"  then "bg-emerald-500"
    when "warn" then "bg-amber-500"
    else             "bg-primary"
    end
  end

  # "13 may 2026" — used in dividend tables, FY headers, etc.
  # Pass `include_year: false` for compact contexts (chart x-axis labels)
  # where horizontal space is tight and the year is redundant.
  def short_date_es(date, include_year: true)
    return "—" if date.nil?

    l(date, format: include_year ? :day_month_year : :day_month)
  end

  # "may 26" — the EPS chart's x-axis, where a month and a two-digit year is all
  # that fits. strftime("%b %y") was rendering English month names here.
  def short_month_year_es(date)
    return "—" if date.nil?

    l(date, format: :month_year)
  end

  # "13 MAY 2026" — uppercase variant for compact eyebrow contexts.
  def short_date_upper_es(date, include_year: true)
    return "—" if date.nil?

    l(date, format: include_year ? :day_month_year_upper : :day_month_upper)
  end

  # Es-MX caption shown below the chart card. It reads the provenance actually
  # recorded rather than asserting one from the asset type, which is how it came
  # to name Yahoo for BMV prices that arrive from DataBursatil.
  def asset_data_source_caption(asset)
    source = MarketData::Queries::PriceSeries.for(asset).latest(1).first&.source
    label = source_label(source) || fallback_source_label(asset)
    venue = asset.asset_type_crypto? ? nil : asset.exchange.presence
    venue = nil if venue && label.end_with?(venue)

    [ "Fuente: #{label}", venue, asset.currency ].compact.join(" · ")
  end

  # Provenance is stored as provider/sub-source (Alpaca/sip, DataBursatil/biva)
  # because the sub-source decides the number. The reader is shown the venue
  # only where it names a real market.
  def source_label(source)
    return nil if source.blank? || source.start_with?("legacy:") || source == "unknown"

    provider, sub_source = source.split("/", 2)
    sub_source.in?(%w[bmv biva]) ? "#{provider} · #{sub_source.upcase}" : provider
  end

  # Nothing recorded yet -- a freshly added asset before its first sync.
  def fallback_source_label(asset)
    return "CoinGecko" if asset.asset_type_crypto?
    return "Banxico" if asset.asset_type_fixed_income?

    asset.data_source.presence || "sin registrar"
  end

  # Returns the visible tab list for an asset, in es-MX. Adaptive per #93:
  # crypto/ETF/fixed_income trim away tabs they cannot populate, equity
  # may still drop tabs when underlying data is missing.
  def asset_detail_tabs(asset, has_fundamentals:, has_dividends:, has_statements:)
    return [] if asset.asset_type_fixed_income?

    tabs = [ { key: :resumen, label: "Resumen" } ]

    if asset.asset_type_crypto?
      tabs << { key: :mercado, label: "Mercado" } if has_fundamentals
      return tabs
    end

    tabs << { key: :valoracion, label: "Valoración" } if has_fundamentals
    tabs << { key: :dividendos, label: "Dividendos" } if has_dividends
    tabs << { key: :estados,    label: "Estados financieros" } if has_statements
    tabs
  end
end
