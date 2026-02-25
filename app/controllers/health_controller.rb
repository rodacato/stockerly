# Unauthenticated JSON health endpoint for uptime monitors and Kamal.
# Returns { status: "ok"|"degraded"|"critical", checks: {...} }
class HealthController < ActionController::API
  CHECKS = {
    prices: { ok: 15.minutes, degraded: 1.hour },
    indices: { ok: 20.minutes, degraded: 2.hours },
    fx_rates: { ok: 2.hours, degraded: 6.hours }
  }.freeze

  def show
    checks = evaluate_checks
    overall = derive_status(checks)

    render json: { status: overall, checks: checks, timestamp: Time.current.iso8601 },
           status: overall == "critical" ? :service_unavailable : :ok
  end

  private

  def evaluate_checks
    {
      prices: check_freshness(:prices, latest_price_sync),
      indices: check_freshness(:indices, latest_indices_sync),
      fx_rates: check_freshness(:fx_rates, latest_fx_sync)
    }
  end

  def check_freshness(key, last_sync_at)
    return "ok" unless last_sync_at

    age = Time.current - last_sync_at
    thresholds = CHECKS[key]

    if age <= thresholds[:ok]
      "ok"
    elsif age <= thresholds[:degraded]
      "degraded"
    else
      "critical"
    end
  end

  def latest_price_sync
    Asset.where(sync_status: :active).maximum(:price_updated_at)
  end

  def latest_indices_sync
    SystemLog.where("task_name LIKE ?", "Market Indices%").where(severity: :success).maximum(:created_at)
  end

  def latest_fx_sync
    SystemLog.where(task_name: "FX Rates Sync").where(severity: :success).maximum(:created_at)
  end

  def derive_status(checks)
    values = checks.values
    return "critical" if values.include?("critical")
    return "degraded" if values.include?("degraded")

    "ok"
  end
end
