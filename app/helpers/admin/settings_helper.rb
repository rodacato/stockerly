module Admin
  module SettingsHelper
    SETTING_LABEL_KEYS = {
      "maintenance_mode"            => "mantenimiento",
      "auto_sync_enabled"           => "sync",
      "email_notifications_enabled" => "correo",
      "developer_mode"              => "desarrollador"
    }.freeze

    def setting_audit_key(key)
      label = SETTING_LABEL_KEYS[key.to_s]
      label ? t("admin.settings.show.#{label}") : key.to_s
    end

    def setting_audit_value(value)
      case value.to_s
      when "true"  then t("admin.settings.show.activado")
      when "false" then t("admin.settings.show.desactivado")
      when "", nil then "—"
      else value.to_s
      end
    end
  end
end
