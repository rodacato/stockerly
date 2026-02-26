# frozen_string_literal: true

# Silence Solid Queue's internal polling logs in production.
# The dispatcher polls every 0.1-1s generating constant noise in STDOUT.
# Only warnings and errors are relevant for operational monitoring.
Rails.application.config.after_initialize do
  if Rails.env.production?
    SolidQueue.logger.level = :warn
  end
end
