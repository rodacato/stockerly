module Admin
  module SettingsHelper
    SETTING_LABELS = {
      "registration_open"           => "registro_abierto",
      "maintenance_mode"            => "modo_mantenimiento",
      "auto_sync_enabled"           => "sincronizacion_automatica",
      "email_notifications_enabled" => "notificaciones_por_correo"
    }.freeze

    def setting_audit_key(key)
      SETTING_LABELS[key.to_s] || key.to_s
    end

    def setting_audit_value(value)
      case value.to_s
      when "true"  then "on"
      when "false" then "off"
      when "", nil then "—"
      else value.to_s
      end
    end

    # "21 MAY 2026 · 14:32" — absolute, mono-friendly. Uses Time.zone with a
    # CDMX fallback (zone is configured globally; the fallback only kicks in
    # if the app boots without an explicit zone).
    def setting_absolute_ts(time)
      return "—" unless time
      zone = Time.zone || ActiveSupport::TimeZone["America/Mexico_City"]
      t = time.in_time_zone(zone)
      "#{t.day.to_s.rjust(2, '0')} #{DatetimeEsHelper::MONTHS_ES[t.month - 1]} #{t.year} · #{t.strftime('%H:%M')}"
    end

    # "hace 6 d · 15 MAY 2026" — combined relative + absolute (Stripe-style).
    def setting_applied_label(time)
      return "sin cambios registrados" unless time
      relative = setting_relative(time)
      "#{relative} · #{setting_absolute_ts(time)}"
    end

    def setting_relative(time)
      seconds = (Time.current - time).to_i
      return "hace #{seconds} s" if seconds < 60
      return "hace #{seconds / 60} min" if seconds < 3600
      return "hace #{seconds / 3600} h" if seconds < 86_400
      "hace #{seconds / 86_400} d"
    end
  end
end
