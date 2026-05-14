Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.environment = ENV.fetch("SENTRY_ENVIRONMENT", Rails.env)
  config.release = ENV["SENTRY_RELEASE"]
  config.traces_sample_rate = ENV.fetch("SENTRY_TRACES_SAMPLE_RATE", "0.0").to_f
  config.send_default_pii = false
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]
  # Silence Sentry in test/development unless DSN explicitly set
  config.enabled_environments = %w[production staging] unless ENV["SENTRY_DSN"].present? && Rails.env.development?
end
