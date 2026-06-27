module Admin
  module UsersHelper
    # Two-letter initials in primary tint — mirrors the mockup pattern and the
    # navbar avatar elsewhere in the app.
    def admin_user_initials(user)
      parts = user.full_name.to_s.strip.split(/\s+/)
      first = parts[0]&.chr.to_s
      last  = parts[1]&.chr.to_s
      "#{first}#{last}".upcase.presence || "?"
    end

    # Es-MX three-letter month formatting: "12 MAY 2026".
    def admin_user_registration_label(user)
      d = user.created_at.to_date
      "#{d.day.to_s.rjust(2, '0')} #{DatetimeEsHelper::MONTHS_ES[d.month - 1]} #{d.year}"
    end

    # Returns the lifecycle status used by the filter chip group: active,
    # suspended, or unverified (no confirmed email yet).
    def admin_user_lifecycle_status(user)
      return :suspended  if user.suspended?
      return :unverified unless user.email_verified?
      :active
    end

    def admin_user_status_label(status)
      { active: "Activo", suspended: "Suspendido", unverified: "Sin verificar" }[status]
    end

    # Lumen semantic pill classes per status — positive/negative/warning.
    def admin_user_status_pill_classes(status)
      {
        active:     "bg-emerald-500/12 text-emerald-700 dark:text-emerald-300",
        suspended:  "bg-rose-500/12 text-rose-700 dark:text-rose-300",
        unverified: "bg-amber-500/14 text-amber-700 dark:text-amber-300"
      }[status]
    end

    # Approximate last activity. There is no last-sign-in column yet, so we
    # surface `updated_at` as a proxy (changes on suspension, role change,
    # profile edit). Unverified users show "sin sesión iniciada".
    def admin_user_last_activity(user)
      return [ nil, "sin sesión iniciada" ] unless user.email_verified?

      ts  = user.updated_at
      now = Time.current
      diff = (now - ts).to_i

      relative =
        if diff < 60        then "hace #{diff} s"
        elsif diff < 3600   then "hace #{diff / 60} min"
        elsif diff < 86_400 then "hace #{diff / 3600} h"
        elsif diff < 604_800 then "hace #{diff / 86_400} d"
        else
          d = ts.to_date
          "#{d.day.to_s.rjust(2, '0')} #{DatetimeEsHelper::MONTHS_ES[d.month - 1]} #{d.year}"
        end

      absolute =
        if ts.to_date == Date.current
          ts.in_time_zone("America/Mexico_City").strftime("%H:%M")
        else
          d = ts.to_date
          "#{d.day.to_s.rjust(2, '0')} #{DatetimeEsHelper::MONTHS_ES[d.month - 1]} #{d.year}"
        end

      [ relative, absolute ]
    end

    def admin_users_filter_active?(key, slug, default: "todos")
      (params[key].presence || default) == slug
    end
  end
end
