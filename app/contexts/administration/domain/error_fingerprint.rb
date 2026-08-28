module Administration
  module Domain
    # Groups occurrences of the same failure. Two exceptions are the same error
    # when the class and the first application frame match — the gem frames
    # below it vary with the call path and would split one bug into many rows.
    class ErrorFingerprint
      BACKTRACE_LIMIT = 30
      DIGEST_LENGTH = 32
      UNKNOWN_LINE = "unknown".freeze

      class << self
        def digest(exception_class, app_line)
          Digest::SHA256.hexdigest("#{exception_class}|#{app_line}")[0, DIGEST_LENGTH]
        end

        # Application frames first, gem noise dropped. Falls back to the raw
        # frames when the whole trace is library code.
        def clean(backtrace)
          lines = Array(backtrace)
          cleaned = Rails.backtrace_cleaner.clean(lines)
          (cleaned.presence || lines).first(BACKTRACE_LIMIT)
        end
      end
    end
  end
end
