module ProfilesHelper
  # Compact one-line label for an active session. Parses common
  # browser / OS hints from a raw user-agent string. Best-effort —
  # no dependency on the `user_agent` gem since the label is only
  # informational, not a routing key.
  def session_user_agent_label(user_agent)
    ua = user_agent.to_s
    return "Sesión sin identificar" if ua.blank?

    browser =
      case ua
      when /Edg\//      then "Edge"
      when /Chrome\//   then "Chrome"
      when /Firefox\//  then "Firefox"
      when /Safari\//   then "Safari"
      else                   "Navegador"
      end

    os =
      case ua
      when /Mac OS X|Macintosh/ then "macOS"
      when /Windows NT/         then "Windows"
      when /Linux/              then "Linux"
      when /iPhone|iPad/        then "iOS"
      when /Android/            then "Android"
      else                            "desconocido"
      end

    "#{browser} · #{os}"
  end

  # "Activa ahora" / "Hace X horas" / "DD MMM YYYY" — depending on how
  # recent the timestamp is. Pluralizes the "días" form correctly and
  # uses explicit boundaries instead of case/in (which compares float
  # deltas against integer ranges unreliably).
  def session_when_text(timestamp)
    return "—" if timestamp.nil?
    delta = Time.current - timestamp

    if delta < 5.minutes
      "Activa ahora"
    elsif delta < 1.hour
      "Hace #{(delta / 60).to_i} min"
    elsif delta < 1.day
      "Hace #{(delta / 3600).to_i} h"
    elsif delta < 7.days
      days = (delta / 86_400).to_i
      "Hace #{days} #{days == 1 ? 'día' : 'días'}"
    else
      timestamp.strftime("%d %b %Y")
    end
  end
end
