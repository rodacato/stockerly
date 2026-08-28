# The instance's own error tracker. ActiveSupport's executor reports every
# unhandled exception from a request or a job through Rails.error, so one
# subscription covers both without a middleware of our own. See ADR-020.
Rails.application.config.after_initialize do
  Rails.error.subscribe(Administration::Handlers::RecordUnhandledError)
end
