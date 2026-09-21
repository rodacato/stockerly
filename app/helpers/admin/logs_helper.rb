module Admin
  module LogsHelper
    SEVERITIES = %w[success warning error].freeze
    MODULE_NAMES = %w[sync alerts auth admin].freeze
    RANGES = %w[hoy 24h 7d 30d 90d].freeze

    DEFAULT_RANGE = "24h".freeze

    # Each filter control reads [ slug, label, value ]: the slug marks the
    # active chip, the value is what the query string carries, and "todos"
    # carries no value because it is the absence of the filter.
    def admin_log_severity_options
      [ [ "todos", t("admin.logs.index.todos"), nil ] ] +
        SEVERITIES.map { |severity| [ severity, t("admin.logs.index.severidades.#{severity}"), severity ] }
    end

    # A module is named by the code that writes the log, so its own name is
    # the label.
    def admin_log_module_options
      [ [ "todos", t("admin.logs.index.todos"), nil ] ] +
        MODULE_NAMES.map { |name| [ name, name, name ] }
    end

    def admin_log_range_options
      RANGES.map { |range| [ range, t("admin.logs.index.rangos.#{range}"), range ] }
    end

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

    def admin_logs_any_filter_active?
      params[:search].present? || params[:severity].present? ||
        params[:module_name].present? || params[:range].present?
    end
  end
end
