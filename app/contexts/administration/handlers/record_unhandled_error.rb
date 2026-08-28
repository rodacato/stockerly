module Administration
  module Handlers
    # Subscribed to Rails.error at boot. ActiveSupport's executor already
    # reports every unhandled exception from a request or a job, so this
    # listens instead of wrapping anything itself.
    class RecordUnhandledError
      class << self
        def report(error, handled: false, severity: nil, context: {}, source: nil)
          return if handled

          origin = origin_of(context)
          UseCases::Errors::RecordError.call(error: error, **origin)
        rescue StandardError
          # A reporter that raises turns one broken request into two, and the
          # second one is unreportable by construction.
          nil
        end

        private

        def origin_of(context)
          controller = context[:controller]
          job = context[:job]

          return from_request(controller.request) if controller.respond_to?(:request)
          return from_job(job) if job

          { source: "other", context: {} }
        end

        def from_request(request)
          {
            source: "request",
            context: {
              reference: request.request_id,
              request_method: request.request_method,
              request_path: request.path,
              request_params: request.filtered_parameters
            }
          }
        end

        def from_job(job)
          { source: "job", context: { reference: job.job_id, job_class: job.class.name } }
        end
      end
    end
  end
end
