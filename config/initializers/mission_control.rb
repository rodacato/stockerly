# Mission Control – Jobs dashboard configuration.
# Auth is the admin routing constraint (see config/routes.rb), not HTTP Basic.
# Set the module accessor directly: the `config.mission_control.jobs.*` form is
# read by the engine before app initializers run, so it never takes effect and
# the dashboard 401s with basic-auth enabled-but-unconfigured.
Rails.application.config.after_initialize do
  MissionControl::Jobs.http_basic_auth_enabled = false
end
