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
  # recent the timestamp is. Keeps the session list readable without a
  # tooltip layer.
  def session_when_text(timestamp)
    return "—" if timestamp.nil?
    delta = Time.current - timestamp
    case delta
    when 0..5.minutes  then "Activa ahora"
    when 0..1.hour     then "Hace #{(delta / 60).to_i} min"
    when 0..1.day      then "Hace #{(delta / 3600).to_i} h"
    when 0..7.days     then "Hace #{(delta / 86_400).to_i} días"
    else                    timestamp.strftime("%d %b %Y")
    end
  end
end
