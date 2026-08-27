module ApplicationHelper
  # The two logo files, named for the theme each is drawn for. Callers needing a
  # fixed variant (an always-indigo panel, an email that cannot swap) ask here
  # instead of hardcoding a filename.
  LOGO_ASSETS = { light: "logo_light.svg", dark: "logo_dark.svg" }.freeze

  def brand_logo(variant)
    LOGO_ASSETS.fetch(variant)
  end

  # The one asset-type glossary (D48) — four surfaces name a kind, and the
  # copies of it used to disagree on two of its five values.
  def asset_type_label_es(asset_type)
    t("comun.tipo_activo.#{asset_type}", default: asset_type.to_s.humanize)
  end

  # Renders a duration in es-MX human form: "2 horas", "1 hora", "30 minutos".
  # Rails' `distance_of_time_in_words` rounds ("about 1 day"); these are exact,
  # because they state a configured limit rather than an elapsed time.
  def duration_in_words_es(duration)
    seconds = duration.to_i
    if seconds % 1.hour.to_i == 0
      hours = seconds / 1.hour.to_i
      hours == 1 ? "1 hora" : "#{hours} horas"
    elsif seconds % 1.minute.to_i == 0
      minutes = seconds / 1.minute.to_i
      minutes == 1 ? "1 minuto" : "#{minutes} minutos"
    else
      "#{seconds} segundos"
    end
  end
end
