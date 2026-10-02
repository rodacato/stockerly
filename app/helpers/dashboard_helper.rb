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

  def sentiment_delta(delta)
    return nil if delta.nil? || delta.zero?

    { arrow: delta.positive? ? "▲" : "▼", text: "#{delta.positive? ? "+" : "−"}#{delta.abs}" }
  end
end
