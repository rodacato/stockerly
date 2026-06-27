module DatetimeEsHelper
  # Shared es-MX abbreviated date parts, indexed for direct use:
  #   MONTHS_ES[date.month - 1]  → "ENE".."DIC"
  #   WEEKDAYS_ES[date.wday]     → "DOM".."SÁB"
  # Each helper still owns its own output format; only the labels are shared.
  MONTHS_ES   = %w[ENE FEB MAR ABR MAY JUN JUL AGO SEP OCT NOV DIC].freeze
  WEEKDAYS_ES = %w[DOM LUN MAR MIÉ JUE VIE SÁB].freeze
end
