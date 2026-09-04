# Single source of truth for market-data sync freshness.
#
# One measure, three readers: the /health monitor (per-source ok/degraded/
# critical status), the Prometheus `stockerly_data_age_seconds` gauge, and
# CheckSyncHealthJob's owner notification (#504). Keeping all of them on the
# same queries avoids drift between what the dashboard reports and what the
# owner is told.
#
# The operator and the owner read the same age against different thresholds.
# /health is looked at on purpose and wants the early warning; a notification
# arrives unasked, so `owner` waits for a silence the next scheduled run
# cannot still cure.
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
  # turns; before that, silence only means the opening bell just rang.
  SESSION_GRACE = 60.minutes

  # types/country select the assets one sync route refreshes; market names the
  # session it depends on, or nil when it runs regardless of market hours.
  PRICE_CHECKS = {
    prices_crypto: { types: %i[crypto], market: nil, ok: 15.minutes, degraded: 1.hour, owner: 6.hours },
    prices_us: { types: %i[stock etf], country: :us, market: :us, ok: 15.minutes, degraded: 1.hour,
                 owner: 6.hours },
    prices_mx: { types: %i[stock etf], country: :mx, market: :bmv, ok: 15.minutes, degraded: 1.hour,
                 owner: 6.hours },
    # CETES are auctioned weekly and synced Sunday 10:00, so a day of silence
    # is normal and nine days is two missed auctions — dead either way, so the
    # operator and the owner share the number.
    prices_fixed_income: { types: %i[fixed_income], market: nil, ok: 8.days, degraded: 9.days, owner: 9.days }
  }.freeze

  CHECKS = PRICE_CHECKS.merge(
    # SyncMarketIndicesJob returns early unless a US or MX session is open, so
    # judging its age overnight asks a question the schedule cannot answer.
    indices: { market: :us_or_bmv, ok: 20.minutes, degraded: 2.hours, owner: 6.hours },
    fx_rates: { market: nil, ok: 2.hours, degraded: 6.hours, owner: 25.hours }
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
      CHECKS.keys.index_with { |key| check_status(key) }
    end

    def overall_status(checks = self.checks)
      values = checks.values
      return "critical" if values.include?("critical")
      return "degraded" if values.include?("degraded")

      "ok"
    end

    # The owner-facing rendering: which routes have been silent past the point
    # the next scheduled run could still cure, mapped to the window they broke.
    def stale_for_owner
      CHECKS.each_with_object({}) do |(key, check), stale|
        next unless due?(key)
        next unless measurable?(key)

        last = last_sync_at(key)
        stale[key] = check[:owner] if last.nil? || last < check[:owner].ago
      end
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

    def last_sync_at(key)
      case key
      when :indices then latest_indices_sync
      when :fx_rates then latest_fx_sync
      else latest_price_sync_for(key)
      end
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

    def check_status(key)
      return "ok" unless due?(key)

      status_for(key, last_sync_at(key))
    end

    # A route that only runs while a market is open cannot be judged while it
    # is closed: at 09:31 ET every US price is yesterday's close and that is
    # not a fault.
    def due?(key)
      session_underway?(CHECKS.fetch(key)[:market])
    end

    # A route with no assets to refresh has nothing that can go stale. Absence
    # of a *log* is different — it means the sync never once reported, which is
    # the silence the owner watch exists for.
    def measurable?(key)
      return true unless PRICE_CHECKS.key?(key)

      price_scope(key).exists?
    end

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
      when :us_or_bmv then grace_elapsed?(MarketHours.us_minutes_since_open) ||
                            grace_elapsed?(MarketHours.bmv_minutes_since_open)
      else true
      end
    end

    def grace_elapsed?(minutes_since_open)
      minutes_since_open.present? && minutes_since_open.minutes >= SESSION_GRACE
    end
  end
end
