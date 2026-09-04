# Hourly observability sweep that turns silent sync failures into a notice the
# owner actually receives (#328).
#
# There is one measure of health and two renderings of it (#504). DataFreshness
# holds the measure — per-route age, its thresholds and the market gating — and
# /health renders it for the operator while this job renders it for the owner.
# Reading SystemLog per sync name instead meant the two could disagree, and
# they did: a dead US price feed degraded /health and notified nobody, because
# SyncPriorityAssetsJob fans out to one job per ticker and writes no summary
# row for a monitor to watch.
#
# Two syncs stay on their logs. News and Earnings report counts, and zero new
# items is legitimately not an error, so the only dated fact that means
# "healthy" is the success row itself. Neither writes data with a threshold on
# it, and inventing one would be the check making up policy.
#
# Dedup: Solid Cache (Rails.cache) keyed by watch, 6h TTL. Two consecutive
# hourly runs against the same stuck sync produce only one alert.
class CheckSyncHealthJob < ApplicationJob
  queue_as :default

  # A stale sync is acute and six hours is the right nag. An exhausted calendar
  # is a chore with a month of runway, so it asks once a week instead.
  DEDUP_TTL          = 6.hours
  CALENDAR_DEDUP_TTL = 7.days
  CACHE_NAMESPACE    = "sync_health_alert".freeze

  # window: the longest silence this sync's own cadence can legitimately
  # produce. task_name must match the string the job passes to SyncLogging
  # exactly (see app/jobs/concerns/sync_logging.rb).
  LOG_WATCHES = {
    news:     { task_name: "News Sync",     window: 25.hours },  # every 30 min
    earnings: { task_name: "Earnings Sync", window: 26.hours }   # daily 09:00
  }.freeze

  # Every gate in this job and in /health rests on MarketHours knowing the
  # holidays, and MarketHours rests on a seed file somebody has to update. It
  # fails open — past the last seeded date every holiday reads as a trading day
  # and the false alarms come back — so the shortfall has to be said out loud
  # before it arrives. Banxico is seeded too but nothing here reads it; its
  # consumer is the CETE auction evaluator, and its runway is that owner's.
  CALENDARS = { calendar_us: :NYSE, calendar_bmv: :BMV }.freeze

  CALENDAR_RUNWAY = 30.days

  def perform
    LOG_WATCHES.each { |key, watch| check_log(key, watch) }
    DataFreshness.stale_for_owner.each { |key, window| alert_stale(key, window) }
    CALENDARS.each { |key, market| check_calendar(key, market) }
  end

  private

  def check_log(key, watch)
    task_name, window = watch.values_at(:task_name, :window)
    logs = SystemLog.where(task_name: task_name).where("created_at > ?", window.ago)

    return if logs.exists?(severity: :success) # recent success cures prior errors

    last_error = logs.where(severity: :error).order(created_at: :desc).first
    phrase     = window_phrase(window)

    alert(
      key,
      task_name: task_name,
      title: title_for(key, phrase),
      record: log_record_message(phrase, last_error),
      body: log_body(last_error)
    )
  end

  # Freshness knows the data is old; it does not know why. Saying so and
  # pointing at Registros is the honest shape — naming whichever error happens
  # to be most recent would present one ticker's 404 as the reason a whole
  # route went quiet.
  def alert_stale(key, window)
    phrase = window_phrase(window)

    alert(
      key,
      task_name: "Freshness: #{key}",
      title: title_for(key, phrase),
      record: I18n.t("notificaciones.sincronizacion.registro_datos", tiempo: phrase),
      body: I18n.t("notificaciones.sincronizacion.cuerpo_sin_datos")
    )
  end

  def check_calendar(key, market)
    through = MarketData::Queries::MarketCalendar.covered_through(market: market)
    return if through && through > CALENDAR_RUNWAY.from_now.to_date

    statement = calendar_statement(through)

    alert(
      key,
      task_name: "Calendar: #{market}",
      title: title_for(key),
      record: statement,
      body: statement
    )
  end

  def calendar_statement(through)
    return I18n.t("notificaciones.sincronizacion.cuerpo_calendario_vacio") if through.nil?

    I18n.t("notificaciones.sincronizacion.cuerpo_calendario", fecha: I18n.l(through, format: :long))
  end

  # Two readers, one dedup. The SystemLog row is the record Registros can show,
  # and the notification is the only one that goes looking for the owner
  # instead of waiting to be looked at.
  def alert(key, task_name:, title:, record:, body:)
    return if recently_alerted?(key)

    record_finding(task_name, record)
    notify_owner(title, body)
    mark_alerted(key)
  rescue StandardError => e
    # Never let an observability sweep crash itself — log and move on so the
    # next hour's run still happens.
    Rails.logger.error("CheckSyncHealthJob: failed to alert on #{key}: #{e.class} #{e.message}")
  end

  # The individual errors are already in Registros; this row is the pattern
  # over them, which is what the notification points back to.
  def record_finding(task_name, message)
    SystemLog.create!(
      task_name: task_name,
      module_name: "health",
      severity: :error,
      error_message: message
    )
  end

  # One account per instance by design (ADR-0010), so the first user is the
  # owner. No user at all means setup never ran and there is nobody to tell.
  def notify_owner(title, body)
    owner = User.first
    return if owner.nil?

    Notifications::UseCases::CreateNotification.call(
      user_id: owner.id,
      title: title,
      body: body,
      notification_type: :system
    )
  end

  def log_record_message(phrase, last_error)
    if last_error
      return I18n.t("notificaciones.sincronizacion.registro_error",
                    tiempo: phrase, error: last_error.error_message)
    end

    I18n.t("notificaciones.sincronizacion.registro_sin_registros", tiempo: phrase)
  end

  # A sync that logged nothing at all is not healthy, it is unobserved — so the
  # notification says that rather than dereference an error that is not there.
  def log_body(last_error)
    return I18n.t("notificaciones.sincronizacion.cuerpo_error", error: last_error.error_message) if last_error

    I18n.t("notificaciones.sincronizacion.cuerpo_sin_registros")
  end

  def title_for(key, phrase = nil)
    I18n.t("notificaciones.sincronizacion.titulo.#{key}", tiempo: phrase)
  end

  # The window is part of the finding: "no success in 6 hours" and "no success
  # in 9 days" are different facts about two syncs with different cadences.
  def window_phrase(window)
    hours = (window / 1.hour).to_i
    return I18n.t("notificaciones.sincronizacion.horas", count: hours) if hours < 24

    I18n.t("notificaciones.sincronizacion.dias", count: (window / 1.day).to_i)
  end

  def recently_alerted?(key)
    Rails.cache.read(dedup_key(key)).present?
  rescue StandardError => e
    Rails.logger.error("CheckSyncHealthJob: dedup read failed for #{key}: #{e.class} #{e.message}")
    false
  end

  def mark_alerted(key)
    ttl = CALENDARS.key?(key) ? CALENDAR_DEDUP_TTL : DEDUP_TTL
    Rails.cache.write(dedup_key(key), Time.current.iso8601, expires_in: ttl)
  rescue StandardError => e
    Rails.logger.error("CheckSyncHealthJob: dedup write failed for #{key}: #{e.class} #{e.message}")
  end

  def dedup_key(key)
    "#{CACHE_NAMESPACE}:#{key}"
  end
end
