module DashboardHelper
  # First-name extraction for greetings. "Adrian Castillo" → "Adrian".
  def first_name_of(user)
    user.full_name.to_s.split.first || user.email.split("@").first
  end

  # ADR-013: the verb exists only as a lookup over a persisted observation.
  # No row, no chip — this returns nil and the caller renders nothing.
  def observation_action(observation)
    MarketData::Domain::ObservationAction.for(observation.observation_type)
  end

  def observation_reading(observation)
    MarketData::Domain::ObservationAction.reading(observation.observation_type)
  end

  # The classification arrives from an external gateway, so an unmapped value
  # renders as itself rather than raising on the whole screen.
  def sentiment_label(key)
    t("comun.clasificacion.#{key}", default: key.to_s.humanize)
  end

  # Percentage points, which is not a percentage: the difference between two
  # returns is stated in points so it is never read as a return of its own.
  def signed_points(points)
    value = points.to_f
    magnitude = "#{number_with_precision(value.abs, precision: 1)} pts"
    return magnitude if comparison_standing(value) == :level

    "#{value.negative? ? "−" : "+"}#{magnitude}"
  end

  # A difference that prints as 0.0 is a tie, whatever sign it carries underneath.
  def comparison_standing(points)
    value = points.to_f.round(1)
    return :level if value.zero?

    value.negative? ? :behind : :ahead
  end

  def comparison_chip(standing, level_label)
    case standing
    when :ahead then [ "bg-positive-bg text-positive-fg", t("portfolios.show.vas_arriba") ]
    when :behind then [ "bg-negative-bg text-negative-fg", t("portfolios.show.vas_abajo") ]
    else [ "bg-bg-muted text-fg-default", level_label ]
    end
  end

  # Maps a points difference onto the same 0-100 track the sentiment cards use.
  # Past this distance more of it stops being informative.
  COMPARISON_TRACK_POINTS = 10

  def comparison_offset(points)
    (50 + (points.to_f.clamp(-COMPARISON_TRACK_POINTS, COMPARISON_TRACK_POINTS) * 5)).round
  end

  # A dot pinned to an edge reports a distance it does not have, so the ends
  # name where the track stops measuring.
  def comparison_track_ends
    [ signed_points(-COMPARISON_TRACK_POINTS), signed_points(COMPARISON_TRACK_POINTS) ]
  end

  # The dot's position on the 0-100 fear/greed track.
  def sentiment_offset(value)
    value.to_i.clamp(0, 100)
  end

  VOLATILITY_SCALE_MAX = 40

  def volatility_offset(value)
    (value.to_f / VOLATILITY_SCALE_MAX * 100).round.clamp(0, 100)
  end

  def sentiment_delta(delta)
    return nil if delta.nil? || delta.zero?

    { arrow: delta.positive? ? "▲" : "▼", text: "#{delta.positive? ? "+" : "−"}#{delta.abs}" }
  end

  # The line under the verdict: the benchmark when there is one to state, and
  # never a comparison over quotes the view cannot vouch for.
  def hoy_subtitle(state, vs_cetes, has_plan: false)
    vs = vs_cetes && t("dashboard.hoy.vas", points: signed_points(vs_cetes[:points]))

    case state
    when :items then vs && "#{vs.upcase_first}."
    when :calm then [ (has_plan ? t("dashboard.hoy.dentro_del_plan") : t("dashboard.hoy.nada_importante")), vs ].compact.join(" · ").then { |line| vs ? "#{line}." : line }
    when :stale then t("dashboard.hoy.solo_sin_precio")
    when :first_run then t("dashboard.hoy.primera_vez_sub")
    end
  end

  HOY_ITEM_ICONS = { maturity: "schedule", earnings: "event", target: "target", allocation: "pie_chart", contribution: "savings", macro: "account_balance" }.freeze

  PLAN_LABELS = { stocks_share: "acciones", crypto_share: "cripto", fixed_income_share: "renta_fija" }.freeze

  def plan_label(key) = t("dashboard.hoy.plan.#{PLAN_LABELS.fetch(key)}")

  def hoy_item_icon(kind) = HOY_ITEM_ICONS.fetch(kind)

  def hoy_item_title(item)
    key = "dashboard.hoy_item.#{item.kind}.titulo"

    case item.kind
    when :allocation then t(key, label: plan_label(item.subject), actual: item.actual, target: item.target)
    when :contribution then t(key)
    when :macro then t(key, label: item.label, count: item.days)
    when :earnings then t(key, symbols: symbols_sentence(item.assets), count: item.assets.size)
    else t(key, symbol: item.asset.symbol, count: item.days || 0, percent: unsigned_percent(item.gap))
    end
  end

  def hoy_item_detail(item)
    key = "dashboard.hoy_item.#{item.kind}.detalle"

    case item.kind
    when :target then format_currency_mx(item.asset.current_price, currency: item.asset.currency)
    when :earnings then t(key, count: item.days, date: l(item.date, format: :short))
    when :macro then t(key, date: l(item.date, format: :short), tentative: item.tentative ? t("dashboard.hoy_item.macro.tentativa") : "")
    when :allocation then t("dashboard.hoy_item.allocation.#{item.gap.positive? ? 'arriba' : 'abajo'}", count: item.gap.abs)
    when :contribution then t(key, amount: format_currency_mx(item.target, currency: "MXN", precision: 0))
    else t(key, date: l(item.date, format: :short))
    end
  end

  def symbols_sentence(assets)
    assets.map(&:symbol).to_sentence(two_words_connector: " y ", last_word_connector: " y ")
  end

  def hoy_item_path(item)
    case item.kind
    when :allocation then portfolio_path
    when :contribution then new_trade_path
    when :macro then discover_path
    when :earnings then item.assets.one? ? market_asset_path(item.asset.symbol) : assets_path
    else market_asset_path(item.asset.symbol)
    end
  end

  # Wires an element to the shared tooltip controller and tells it which figure
  # to count when the ? opens.
  def help_tip_data(figure)
    { controller: "metric-tooltip", help_url: help_opens_path(figure) }
  end
end
