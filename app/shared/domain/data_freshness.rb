# Single source of truth for market-data sync freshness.
#
# Consumed by the /health monitor (per-source ok/degraded/critical status)
# and by the Prometheus `stockerly_data_age_seconds` gauge (age of the
# freshest sync). Keeping both on the same queries avoids drift between the
# JSON monitor and the scraped metric.
#
# Prices are read per sync route, not as one number over every asset (#553).
# A single `maximum(:price_updated_at)` across all active assets answered "did
# anything update?" while being read as "is everything updating?": crypto syncs
# every 5 minutes around the clock, so one live crypto row reported the whole
# portfolio fresh with every US equity and every BMV issuer stale.
#
# `index` assets are deliberately absent: nothing schedules them and nothing
# should. The VIX level the app reads is a MarketIndex row, refreshed every 10
# minutes by SyncMarketIndicesJob through the yfinance bridge — no sanctioned
# price provider serves an index, which is why that job exists at all. Watching
# the seeded VIX *asset* would be a check that can only ever be red.
class DataFreshness
  # An hour into a session a sync on a 5-30 minute cadence has had several
  # turns; before that, silence only means the opening bell just rang. Same
  # grace CheckSyncHealthJob applies to its market-gated watches.
  SESSION_GRACE = 60.minutes

  # types/country select the assets one sync route refreshes; market names the
  # session it depends on, or nil when it runs regardless of market hours.
  PRICE_CHECKS = {
    prices_crypto: { types: %i[crypto], market: nil, ok: 15.minutes, degraded: 1.hour },
    prices_us: { types: %i[stock etf], country: :us, market: :us, ok: 15.minutes, degraded: 1.hour },
    prices_mx: { types: %i[stock etf], country: :mx, market: :bmv, ok: 15.minutes, degraded: 1.hour },
    # CETES are auctioned weekly and synced Sunday 10:00, so a day of silence
    # is normal and nine days is not — the window CheckSyncHealthJob watches.
    prices_fixed_income: { types: %i[fixed_income], market: nil, ok: 8.days, degraded: 9.days }
  }.freeze

  CHECKS = PRICE_CHECKS.merge(
    indices: { ok: 20.minutes, degraded: 2.hours },
    fx_rates: { ok: 2.hours, degraded: 6.hours }
  ).freeze

  PRICE_ASSET_TYPES = PRICE_CHECKS.values.flat_map { |check| check[:types] }.uniq.freeze

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
      PRICE_CHECKS.keys.index_with { |key| price_status(key) }.merge(
        indices: status_for(:indices, latest_indices_sync),
        fx_rates: status_for(:fx_rates, latest_fx_sync)
      )
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

    # A route that only runs while a market is open cannot be judged while it
    # is closed: at 09:31 ET every US price is yesterday's close and that is
    # not a fault.
    def price_status(key)
      return "ok" unless session_underway?(PRICE_CHECKS.fetch(key)[:market])

      status_for(key, latest_price_sync_for(key))
    end

    def latest_price_sync_for(key)
      price_scope(key).maximum(:price_updated_at)
    end

    # The gauge reports the freshest sync of any kind, so this one stays broad.
    def latest_price_sync
      Asset.syncing.where(asset_type: PRICE_ASSET_TYPES).maximum(:price_updated_at)
    end

    def latest_indices_sync
      SystemLog.where("task_name LIKE ?", "Market Indices%").where(severity: :success).maximum(:created_at)
    end

    # "FX Rate Refresh" is the string RefreshFxRatesJob passes to SyncLogging.
    # This read used to ask for "FX Rates Sync", which nothing writes, so it
    # always found nil and /health always reported FX healthy — including while
    # the refresh was dead. spec/integration/fx_rates_flow_spec.rb runs the real
    # job against this read so the two names cannot drift apart again.
    def latest_fx_sync
      SystemLog.where(task_name: "FX Rate Refresh").where(severity: :success).maximum(:created_at)
    end

    private

    # Same country split SyncPriorityAssetsJob routes on, so the monitor covers
    # exactly what the schedule feeds.
    def price_scope(key)
      check = PRICE_CHECKS.fetch(key)
      scope = Asset.syncing.where(asset_type: check[:types])

      case check[:country]
      when :mx then scope.where(country: "MX")
      when :us then scope.where.not(country: "MX").or(scope.where(country: [ nil, "" ]))
      else scope
      end
    end

    def session_underway?(market)
      case market
      when :us then grace_elapsed?(MarketHours.us_minutes_since_open)
      when :bmv then grace_elapsed?(MarketHours.bmv_minutes_since_open)
      else true
      end
    end

    def grace_elapsed?(minutes_since_open)
      minutes_since_open.present? && minutes_since_open.minutes >= SESSION_GRACE
    end
  end
end
