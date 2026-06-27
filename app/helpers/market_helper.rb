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

  # es-MX label for the asset detail header chip ("Acción", "ETF", "Cripto",
  # "CETE", "Índice"). Used in the new Stockerly-2.0 /market/:symbol header.
  def asset_type_label_es(asset)
    case asset.asset_type
    when "stock"         then "Acción"
    when "etf"           then "ETF"
    when "crypto"        then "Cripto"
    when "fixed_income"  then "CETE"
    when "index"         then "Índice"
    else asset.asset_type.to_s.humanize
    end
  end

  # Native-currency price prefix used on the asset detail header and price
  # chart. Per ADR / S09 convention: "MXN 48.50" / "USD 612.85".
  def asset_currency_price(asset, precision: 2)
    "#{asset.currency} #{number_with_precision(asset.current_price || 0, precision: precision, delimiter: ',')}"
  end

  # Relative-time label in es-MX: "hace 12 min", "hoy", "ayer", "hace 3 días".
  # Used for technical observations in the asset detail page.
  def observation_when(time)
    return "—" if time.nil?

    delta = Time.current - time
    case delta
    when 0...60        then "hace un instante"
    when 60...3600     then "hace #{(delta / 60).to_i} min"
    when 3600...86_400 then "hace #{(delta / 3600).to_i} h"
    when 86_400...172_800 then "ayer"
    else "hace #{(delta / 86_400).to_i} días"
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

  ASSET_MONTHS_ES_LOWER = %w[ene feb mar abr may jun jul ago sep oct nov dic].freeze

  # "13 may 2026" — used in dividend tables, FY headers, etc.
  # Pass `include_year: false` for compact contexts (chart x-axis labels)
  # where horizontal space is tight and the year is redundant.
  def short_date_es(date, include_year: true)
    return "—" if date.nil?

    base = "#{date.day} #{ASSET_MONTHS_ES_LOWER[date.month - 1]}"
    include_year ? "#{base} #{date.year}" : base
  end

  # "13 MAY 2026" — uppercase variant for compact eyebrow contexts.
  def short_date_upper_es(date, include_year: true)
    return "—" if date.nil?

    base = "#{date.day} #{DatetimeEsHelper::MONTHS_ES[date.month - 1]}"
    include_year ? "#{base} #{date.year}" : base
  end

  # Es-MX caption shown below the chart card depending on data source.
  def asset_data_source_caption(asset)
    if asset.asset_type_crypto?
      "Fuente: CoinGecko · #{asset.currency}"
    elsif asset.asset_type_fixed_income?
      "Fuente: Banxico · MXN"
    elsif asset.exchange == "BMV"
      "Fuente: Yahoo Finance · BMV · #{asset.currency}"
    else
      "Fuente: Alpha Vantage · #{asset.exchange || '—'} · #{asset.currency}"
    end
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
