module Administration
  module UseCases
    module Errors
      # One row per distinct failure. The caller is the error subscriber, which
      # runs inside a request or job that is already failing — so this returns
      # the record and never decides anything about the failure itself.
      class RecordError < SimpleUseCase
        MESSAGE_LIMIT = 1_000
        # Re-read on every occurrence: the newest request that hit the bug is
        # more useful than the one that happened to arrive first.
        VOLATILE = %i[message backtrace source reference request_method request_path job_class request_params].freeze

        def call(error:, context: {}, source: "other")
          attrs = attributes_for(error, context, source)
          fingerprint = attrs[:fingerprint]
          record = ErrorEvent.find_by(fingerprint: fingerprint)
          record ? bump(record, attrs) : ErrorEvent.create!(attrs)
        rescue ActiveRecord::RecordNotUnique
          bump(ErrorEvent.find_by!(fingerprint: fingerprint), attrs)
        end

        private

        def attributes_for(error, context, source)
          backtrace = Domain::ErrorFingerprint.clean(error.backtrace)
          app_line = backtrace.first || Domain::ErrorFingerprint::UNKNOWN_LINE
          exception_class = error.class.name
          now = Time.current

          {
            fingerprint: Domain::ErrorFingerprint.digest(exception_class, app_line),
            exception_class: exception_class,
            message: error.message.to_s.truncate(MESSAGE_LIMIT),
            app_line: app_line,
            backtrace: backtrace,
            source: source,
            reference: context[:reference],
            request_method: context[:request_method],
            request_path: context[:request_path],
            job_class: context[:job_class],
            request_params: filtered(context[:request_params]),
            first_seen_at: now,
            last_seen_at: now
          }
        end

        def bump(record, attrs)
          record.increment!(:occurrences, touch: :last_seen_at)
          record.update!(attrs.slice(*VOLATILE))
          record
        end

        # Never trust the caller with this: the filter belongs at the point of
        # write, where a missed one becomes a password on disk. The JSON
        # round-trip drops anything jsonb could not store anyway.
        def filtered(params)
          return {} if params.blank?

          filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
          JSON.parse(filter.filter(params.to_h).to_json)
        rescue StandardError
          {}
        end
      end
    end
  end
end
