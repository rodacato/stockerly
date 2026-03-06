# Mission Control – Jobs dashboard configuration.
# Authentication is handled via routing constraint (admin session check)
# instead of HTTP Basic Auth.
Rails.application.configure do
  config.mission_control.jobs.http_basic_auth_enabled = false
end
