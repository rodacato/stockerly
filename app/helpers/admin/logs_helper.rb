module Admin
  module LogsHelper
    SEVERITY_OPTIONS = [
      [ "todos",   "Todos",  nil ],
      [ "success", "Éxito",  "success" ],
      [ "warning", "Aviso",  "warning" ],
      [ "error",   "Error",  "error" ]
    ].freeze

    MODULE_OPTIONS = [
      [ "todos",  "Todos",  nil ],
      [ "sync",   "sync",   "sync" ],
      [ "alerts", "alerts", "alerts" ],
      [ "auth",   "auth",   "auth" ],
      [ "admin",  "admin",  "admin" ]
    ].freeze

    RANGE_OPTIONS = [
      [ "hoy", "Hoy",          "hoy" ],
      [ "24h", "Últimas 24 h", "24h" ],
      [ "7d",  "7 días",       "7d" ],
      [ "30d", "30 días",      "30d" ],
      [ "90d", "90 días",      "90d" ]
    ].freeze

    DEFAULT_RANGE = "24h".freeze

    def admin_log_severity_dot_classes(severity)
      case severity.to_s
      when "success" then "bg-positive"
      when "warning" then "bg-warning"
      when "error"   then "bg-negative"
      else                "bg-fg-subtle opacity-60"
      end
    end

    # Color classes for the inline severity label inside an expanded panel
    # (the "Severidad · ERROR" meta chip). Centralizes UI-mapping that was
    # otherwise duplicated as a ternary in the row partial.
    def admin_log_severity_text_classes(severity)
      case severity.to_s
      when "success" then "text-positive"
      when "warning" then "text-warning"
      when "error"   then "text-negative"
      else                "text-fg-subtle"
      end
    end

    def admin_log_module_chip(module_name)
      return "—" if module_name.blank?
      module_name
    end

    def admin_log_message(log)
      log.error_message.presence || log.task_name
    end

    def admin_log_payload(log)
      {
        id:            log.log_uid.presence || "log_#{log.id}",
        task:          log.task_name,
        module:        log.module_name,
        severity:      log.severity,
        duration_s:   log.duration_seconds,
        created_at:    log.created_at.iso8601
      }.compact
    end

    def admin_logs_filter_active?(key, slug, default: nil)
      current = params[key].presence
      if default && current.nil?
        return slug == default
      end
      current == slug
    end

    def admin_logs_current_range_label
      current = params[:range].presence || DEFAULT_RANGE
      RANGE_OPTIONS.find { |slug, _, _| slug == current }&.dig(1) || "Últimas 24 h"
    end

    def admin_logs_current_module_label
      current = params[:module_name].presence
      return "Todos" if current.blank?
      current
    end

    def admin_logs_any_filter_active?
      params[:search].present? || params[:severity].present? ||
        params[:module_name].present? || params[:range].present?
    end
  end
end
