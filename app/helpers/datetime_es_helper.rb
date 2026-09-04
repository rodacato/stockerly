module DatetimeEsHelper
  # Shared es-MX date parts and the two time formats every surface reads:
  #   WEEKDAYS_ES[date.wday]     → "DOM".."SÁB"
  #   relative_age(t)            → "hace 20 min"
  #   absolute_stamp(t)          → "03 AGO 2026 · 14:32"
  # Month names are not restated here: they are the locale's own
  # date.abbr_month_names, read through the date.formats that upcase them.
  WEEKDAYS_ES = %w[DOM LUN MAR MIÉ JUE VIE SÁB].freeze

  CDMX = "America/Mexico_City".freeze

  def relative_age(time, blank: "—")
    return blank if time.blank?

    # Clamped: a timestamp a few seconds into the future reads as "hace -1 min".
    seconds = [ (Time.current - time).to_i, 0 ].max

    case seconds
    when 0...60           then "hace un instante"
    when 60...3600        then "hace #{seconds / 60} min"
    when 3600...86_400    then "hace #{seconds / 3600} h"
    when 86_400...172_800 then "ayer"
    else                       "hace #{seconds / 86_400} días"
    end
  end

  def absolute_stamp(time, seconds: false, blank: "—")
    return blank if time.blank?

    # Date and time both come from this one conversion: reading the date off the
    # raw timestamp dated an 18:00 CDMX row tomorrow, because the app runs in UTC.
    l(time.in_time_zone(CDMX), format: seconds ? :stamp_seconds : :stamp)
  end
end
