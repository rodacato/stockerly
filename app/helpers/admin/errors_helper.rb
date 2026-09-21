module Admin
  module ErrorsHelper
    SOURCES = %w[request job other].freeze

    def admin_error_source_options
      [ [ "todos", t("admin.errors.index.todos"), nil ] ] +
        SOURCES.map { |source| [ source, t("admin.errors.index.origenes.#{source}"), source ] }
    end

    # What was running when it blew up, in the shape that identifies it: a verb
    # and a path for a request, the class for a job.
    def admin_error_origin(event)
      return "#{event.request_method} #{event.request_path}" if event.request_path.present?
      return event.job_class if event.job_class.present?

      "—"
    end

    def admin_error_source_classes(source)
      case source.to_s
      when "request" then "bg-primary-muted text-primary-fg"
      when "job"     then "bg-warning-bg text-warning-fg"
      else                "bg-bg-muted text-fg-subtle"
      end
    end

    def admin_errors_any_filter_active?
      params[:search].present? || params[:source].present?
    end
  end
end
