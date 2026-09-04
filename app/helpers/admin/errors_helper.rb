module Admin
  module ErrorsHelper
    SOURCE_OPTIONS = [
      [ "todos",   "Todos",      nil ],
      [ "request", "Peticiones", "request" ],
      [ "job",     "Trabajos",   "job" ],
      [ "other",   "Otros",      "other" ]
    ].freeze

    # What was running when it blew up, in the shape that identifies it: a verb
    # and a path for a request, the class for a job.
    def admin_error_origin(event)
      return "#{event.request_method} #{event.request_path}" if event.request_path.present?
      return event.job_class if event.job_class.present?

      "—"
    end

    def admin_error_source_classes(source)
      case source.to_s
      when "request" then "bg-primary-muted text-primary"
      when "job"     then "bg-warning/10 text-warning"
      else                "bg-bg-muted text-fg-subtle"
      end
    end

    def admin_errors_any_filter_active?
      params[:search].present? || params[:source].present?
    end
  end
end
