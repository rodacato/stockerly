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

  # The kit's Card, as four utilities rather than a partial (D75). The shape is
  # `rounded-2xl` and a border on surface; padding, layout and shadow vary at
  # every one of its call sites and stay there. The tag varies too — section,
  # li, ul, article, aside — which is why this is a helper and not a wrapper.
  CARD_SHAPE = "rounded-2xl border border-border-default bg-bg-surface".freeze

  def card_classes(extra = nil)
    class_names(CARD_SHAPE, extra)
  end

  # The kit's three button weights (D86). The size is chosen by what the button
  # is FOR, not by which surface it sits on: `lg` is the action the screen
  # exists for, `md` a full-width action that is not the point of the screen,
  # `sm` an inline one beside a control. Measured before deciding — 18 of the
  # 35 sites already agreed, and password_resets settled the axis by using both
  # correctly across four screens of one controller.
  #
  # Width and layout stay at the call site, the way D75 left padding on Card's.
  BUTTON_SIZES = {
    lg: "rounded-xl px-4 py-3.5 text-base",
    md: "rounded-lg px-4 py-3 text-sm",
    sm: "rounded-lg px-3 py-2 text-sm"
  }.freeze

  # `text-fg-inverse` and not `text-white`: the token is #0F172A in dark, where
  # white on the dark-mode primary measures 3.06:1 and fails AA.
  BUTTON_VARIANTS = {
    primary: "bg-primary text-fg-inverse hover:bg-primary-hover",
    secondary: "border border-border-default bg-bg-surface text-fg-default hover:border-border-strong",
    danger: "border border-negative bg-bg-surface text-negative hover:bg-negative-bg"
  }.freeze

  def button_classes(variant = :primary, size = :md, extra = nil)
    class_names("font-semibold transition-colors",
                BUTTON_SIZES.fetch(size), BUTTON_VARIANTS.fetch(variant), extra)
  end

  # Field takes the same weight axis, minus the inline one — an input is never
  # the small case, it is the thing the small case sits beside (D86).
  FIELD_SIZES = { lg: "rounded-xl px-4 py-3 text-base", md: "rounded-lg px-3 py-2.5 text-sm" }.freeze

  def field_classes(size = :md, extra = nil)
    class_names("border border-border-default bg-bg-surface text-fg-default placeholder:text-fg-subtle focus:outline-none focus:ring-2 focus:ring-focus",
                FIELD_SIZES.fetch(size), extra)
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
