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
end
