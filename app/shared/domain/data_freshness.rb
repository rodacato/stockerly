# Single source of truth for market-data sync freshness.
#
# Consumed by the /health monitor (per-source ok/degraded/critical status)
# and by the Prometheus `stockerly_data_age_seconds` gauge (age of the
# freshest sync). Keeping both on the same queries avoids drift between the
# JSON monitor and the scraped metric.
class DataFreshness
  CHECKS = {
    prices: { ok: 15.minutes, degraded: 1.hour },
    indices: { ok: 20.minutes, degraded: 2.hours },
    fx_rates: { ok: 2.hours, degraded: 6.hours }
  }.freeze

  class << self
    # Age in seconds of the most recently synced data across all sources,
    # or nil when nothing has synced yet (first boot).
    def newest_data_age_seconds
      latest = latest_sync_at
      latest && (Time.current - latest)
    end

    def latest_sync_at
      [ latest_price_sync, latest_indices_sync, latest_fx_sync ].compact.max
    end

    def checks
      {
        prices: status_for(:prices, latest_price_sync),
        indices: status_for(:indices, latest_indices_sync),
        fx_rates: status_for(:fx_rates, latest_fx_sync)
      }
    end

    def overall_status(checks = self.checks)
      values = checks.values
      return "critical" if values.include?("critical")
      return "degraded" if values.include?("degraded")

      "ok"
    end

    def status_for(key, last_sync_at)
      return "ok" unless last_sync_at

      age = Time.current - last_sync_at
      thresholds = CHECKS.fetch(key)

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
  end
end
