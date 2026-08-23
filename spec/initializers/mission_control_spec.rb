require "rails_helper"

# Regression: the jobs dashboard 401'd because http_basic_auth stayed enabled
# (the config.mission_control.jobs.* form is consumed before app initializers
# run). Auth is the admin routing constraint, so basic auth must be off.
RSpec.describe "Mission Control Jobs auth" do
  it "disables HTTP basic auth so the admin-gated dashboard renders" do
    expect(MissionControl::Jobs.http_basic_auth_enabled).to be(false)
  end
end
