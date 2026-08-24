module DashboardHelper
  # es-MX hour-aware greeting per brand.md §9.
  # 05:00–11:59 → Buenos días
  # 12:00–18:59 → Buenas tardes
  # 19:00–04:59 → Buenas noches
  def dashboard_greeting(time = Time.current)
    case time.hour
    when 5..11  then "Buenos días"
    when 12..18 then "Buenas tardes"
    else             "Buenas noches"
    end
  end

  # Formats an amount as "MXN 1,247,580.40" (ISO code prefix + grouped digits).
  # Defaults to 2 decimals. Use precision: 4 for CETES yields / FX rates.
  # nil is treated as 0 so the precision parameter still applies.
  def format_currency_mx(amount, currency:, precision: 2)
    formatted = number_with_precision(amount || 0, precision: precision, delimiter: ",")
    "#{currency} #{formatted}"
  end

  # First-name extraction for greetings. "Adrian Castillo" → "Adrian".
  def first_name_of(user)
    user.full_name.to_s.split.first || user.email.split("@").first
  end

  # ADR-013: the verb exists only as a lookup over a persisted observation.
  # No row, no chip — this returns nil and the caller renders nothing.
  def observation_action(observation)
    MarketData::Domain::ObservationAction.for(observation.observation_type)
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
    "#{value.negative? ? "−" : "+"}#{number_with_precision(value.abs, precision: 1)} pts"
  end

  # Maps a points difference onto the same 0-100 track the sentiment cards use.
  # Clamped at ±10 points, past which more distance stops being informative.
  def comparison_offset(points)
    (50 + (points.to_f.clamp(-10, 10) * 5)).round
  end

  # The dot's position on the 0-100 fear/greed track.
  def sentiment_offset(value)
    value.to_i.clamp(0, 100)
  end

  def sentiment_delta(delta)
    return nil if delta.nil? || delta.zero?

    { arrow: delta.positive? ? "▲" : "▼", text: "#{delta.positive? ? "+" : "−"}#{delta.abs}" }
  end
end
