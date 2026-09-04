# Hourly observability sweep that turns silent sync failures into a notice the
# owner actually receives (#328).
#
# For each watched sync we look at SystemLog entries inside that sync's own
# window. No success in the window means the sync is either failing or not
# running at all, and either way the owner hears about it once. A recent
# success "cures" prior errors — a sync that hiccupped but recovered is healthy.
#
# One window for all seven was wrong (#504): three of them do not run daily and
# unconditionally, so a normal Saturday read as three dead syncs.
#
#   - "Bulk BMV Sync" only runs while the BMV is open (SyncPriorityAssetsJob)
#   - "Market Indices Sync" returns early unless a US or MX market is open
#   - "CETES Sync" runs once a week, Sunday 10:00
#
# So each watch carries its own window, and the two market-gated ones are only
# evaluated once their session is genuinely underway. Outside the session the
# question is not asked, so silence is never mistaken for failure.
#
# Dedup: Solid Cache (Rails.cache) keyed by task name, 6h TTL. Two consecutive
# hourly runs against the same stuck sync produce only one alert.
#
# Task names must match the strings the sync jobs pass to SyncLogging exactly
# (see app/jobs/concerns/sync_logging.rb).
#
# Out of scope: per-asset Price Sync entries (too granular for hourly cadence),
# Fundamentals/Statements (bursty multi-day), Fear & Greed (auxiliary signal).
class CheckSyncHealthJob < ApplicationJob
  queue_as :default

  DEDUP_TTL       = 6.hours
  CACHE_NAMESPACE = "sync_health_alert".freeze

  # An hour into a session a sync on a 5-30 minute cadence has had several
  # turns. Before that, silence only means the opening bell just rang.
  SESSION_GRACE = 60.minutes

  # window: the longest silence this sync's own cadence can legitimately
  # produce. market: the session it depends on, or nil when it runs regardless.
  WATCHES = {
    "FX Rate Refresh"     => { window: 25.hours, market: nil },        # hourly
    "Bulk Crypto Sync"    => { window: 25.hours, market: nil },        # every 5 min, 24/7
    "News Sync"           => { window: 25.hours, market: nil },        # every 30 min
    "Earnings Sync"       => { window: 26.hours, market: nil },        # daily 09:00
    "CETES Sync"          => { window: 9.days,   market: nil },        # weekly, Sun 10:00
    "Bulk BMV Sync"       => { window: 25.hours, market: :bmv },       # 5-30 min while BMV open
    "Market Indices Sync" => { window: 25.hours, market: :us_or_bmv }  # 10 min while either open
  }.freeze

  CRITICAL_SYNCS = WATCHES.keys.freeze

  # What each sync means to the person affected. "Bulk BMV Sync" is the
  # developer's name for it; the owner holds Mexican shares.
  OWNER_FACING = {
    "FX Rate Refresh"     => "El tipo de cambio no se ha actualizado en más de un día",
    "Bulk BMV Sync"       => "Tus acciones mexicanas no se han actualizado en más de un día",
    "Bulk Crypto Sync"    => "Tus criptomonedas no se han actualizado en más de un día",
    "News Sync"           => "Las noticias no se han actualizado en más de un día",
    "Earnings Sync"       => "El calendario de reportes no se ha actualizado en más de un día",
    "CETES Sync"          => "Las tasas de CETES no se han actualizado en más de una semana",
    "Market Indices Sync" => "Los índices no se han actualizado en más de un día"
  }.freeze

  def perform
    WATCHES.each { |task_name, watch| check(task_name, watch) }
  end

  private

  def check(task_name, watch)
    return unless due?(watch[:market])

    logs = SystemLog.where(task_name: task_name)
                    .where("created_at > ?", watch[:window].ago)

    return if logs.where(severity: :success).exists? # recent success cures prior errors

    alert(
      task_name,
      window: watch[:window],
      last_error: logs.where(severity: :error).order(created_at: :desc).first
    )
  end

  # A sync that only runs while a market is open cannot be judged while it is
  # closed. Asking anyway is what alerted every weekend.
  def due?(market)
    case market
    when :bmv       then session_underway?(MarketHours.bmv_minutes_since_open)
    when :us_or_bmv then session_underway?(MarketHours.us_minutes_since_open) ||
                         session_underway?(MarketHours.bmv_minutes_since_open)
    else true
    end
  end

  def session_underway?(minutes_since_open)
    minutes_since_open.present? && minutes_since_open.minutes >= SESSION_GRACE
  end

  # Two readers, one dedup. The SystemLog row is the record Registros can show,
  # and the notification is the only one that goes looking for the owner
  # instead of waiting to be looked at.
  def alert(task_name, window:, last_error:)
    return if recently_alerted?(task_name)

    record(task_name, window: window, last_error: last_error)
    notify_owner(task_name, last_error: last_error)
    mark_alerted(task_name)
  rescue StandardError => e
    # Never let an observability sweep crash itself — log and move on so the
    # next hour's run still happens.
    Rails.logger.error("CheckSyncHealthJob: failed to alert on #{task_name}: #{e.class} #{e.message}")
  end

  # The individual errors are already in Registros; this row is the pattern
  # over them, which is what the notification points back to.
  def record(task_name, window:, last_error:)
    SystemLog.create!(
      task_name: task_name,
      module_name: "health",
      severity: :error,
      error_message: "Sin sincronización exitosa desde hace más de #{window_phrase(window)}. " \
                     "#{detail_for(last_error)}"
    )
  end

  # The window is part of the finding: "no success in 25 h" and "no success in
  # 9 days" are different facts about two syncs with different cadences.
  def window_phrase(window)
    window < 2.days ? "#{(window / 1.hour).to_i} h" : "#{(window / 1.day).to_i} días"
  end

  # A sync that logged nothing at all is not healthy, it is unobserved — so the
  # summary has to say that rather than dereference an error that is not there.
  def detail_for(last_error)
    return "Sin registros en la ventana." if last_error.nil?

    "Último error: #{last_error.error_message}"
  end

  # One account per instance by design (ADR-0010), so the first user is the
  # owner. No user at all means setup never ran and there is nobody to tell.
  def notify_owner(task_name, last_error:)
    owner = User.first
    return if owner.nil?

    Notifications::UseCases::CreateNotification.call(
      user_id: owner.id,
      title: OWNER_FACING.fetch(task_name, task_name),
      body: "#{last_error&.error_message || 'Sin registros en la ventana'}. Revisa Registros para el detalle.",
      notification_type: :system
    )
  end

  def recently_alerted?(task_name)
    Rails.cache.read(dedup_key(task_name)).present?
  rescue StandardError => e
    Rails.logger.error("CheckSyncHealthJob: dedup read failed for #{task_name}: #{e.class} #{e.message}")
    false
  end

  def mark_alerted(task_name)
    Rails.cache.write(dedup_key(task_name), Time.current.iso8601, expires_in: DEDUP_TTL)
  rescue StandardError => e
    Rails.logger.error("CheckSyncHealthJob: dedup write failed for #{task_name}: #{e.class} #{e.message}")
  end

  def dedup_key(task_name)
    "#{CACHE_NAMESPACE}:#{task_name}"
  end
end
