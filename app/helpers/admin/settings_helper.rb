module Admin
  module SettingsHelper
    SETTING_LABELS = {
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

    # "hace 6 días · 15 MAY 2026" — combined relative + absolute (Stripe-style).
    def setting_applied_label(time)
      return "sin cambios registrados" unless time
      "#{relative_age(time)} · #{absolute_stamp(time)}"
    end
  end
end
