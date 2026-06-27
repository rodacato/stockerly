# Unauthenticated JSON health endpoint for uptime monitors and Kamal.
# Returns { status: "ok"|"degraded"|"critical", checks: {...} }
#
# Freshness logic lives in DataFreshness so this monitor and the
# Prometheus `stockerly_data_age_seconds` gauge stay in sync.
class HealthController < ActionController::API
  def show
    checks = DataFreshness.checks
    overall = DataFreshness.overall_status(checks)

    render json: { status: overall, checks: checks, timestamp: Time.current.iso8601 },
           status: overall == "critical" ? :service_unavailable : :ok
  end
end
