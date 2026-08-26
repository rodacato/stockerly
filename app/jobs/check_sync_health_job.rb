# Hourly observability sweep that turns silent sync failures into a notice the
# owner actually receives. Sentry serves whoever wrote the code; on a
# self-hosted single-user instance that is a different person from the one whose
# data went stale, and only one of them was being told (#328).
#
# For each critical sync task, we look at SystemLog entries in the last 25 hours
# (24h + 1h slack on edges). If we see errors AND no successes in that window,
# we treat the sync as silently failing and fire a single Sentry warning per
# affected task. Recent successes "cure" prior errors — a sync that hiccupped
# but recovered is healthy.
#
# Dedup: Solid Cache (Rails.cache) keyed by task name, 6h TTL. Two consecutive
# hourly runs against the same stuck sync produce only one alert.
#
# Monitored task names (must match the strings used by SystemLog.create! /
# SyncLogging#log_sync_success/log_sync_failure exactly — see app/jobs/
# concerns/sync_logging.rb):
#
#   - "FX Rate Refresh"      (RefreshFxRatesJob — hourly)
#   - "Bulk Stock Sync"      (SyncBulkStocksJob — every 5-30 min via SyncPriorityAssetsJob)
#   - "Bulk BMV Sync"        (SyncBulkBmvJob — every 5-30 min via SyncPriorityAssetsJob)
#   - "Bulk Crypto Sync"     (SyncBulkCryptoJob — every 5 min via SyncPriorityAssetsJob)
#   - "News Sync"            (SyncNewsJob — every 30 min)
#   - "Earnings Sync"        (SyncEarningsJob — daily 9am)
#   - "CETES Sync"           (SyncCetesJob — weekly Sun 10am)
#   - "Market Indices Sync"  (SyncMarketIndicesJob — every 10 min)
#
# Out of scope: per-asset Price Sync entries (too granular for hourly cadence),
# Fundamentals/Statements (bursty multi-day), Fear & Greed (auxiliary signal).
class CheckSyncHealthJob < ApplicationJob
  queue_as :default

  LOOKBACK_WINDOW = 25.hours
  DEDUP_TTL       = 6.hours
  CACHE_NAMESPACE = "sync_health_alert".freeze

  # What each sync means to the person affected. "Bulk BMV Sync" is the
  # developer's name for it; the owner holds Mexican shares.
  OWNER_FACING = {
    "FX Rate Refresh"     => "El tipo de cambio no se ha actualizado en más de un día",
    "Bulk Stock Sync"     => "Tus acciones de EE. UU. no se han actualizado en más de un día",
    "Bulk BMV Sync"       => "Tus acciones mexicanas no se han actualizado en más de un día",
    "Bulk Crypto Sync"    => "Tus criptomonedas no se han actualizado en más de un día",
    "News Sync"           => "Las noticias no se han actualizado en más de un día",
    "Earnings Sync"       => "El calendario de reportes no se ha actualizado en más de un día",
    "CETES Sync"          => "Las tasas de CETES no se han actualizado en más de un día",
    "Market Indices Sync" => "Los índices no se han actualizado en más de un día"
  }.freeze

  CRITICAL_SYNCS = [
    "FX Rate Refresh",
    "Bulk Stock Sync",
    "Bulk BMV Sync",
    "Bulk Crypto Sync",
    "News Sync",
    "Earnings Sync",
    "CETES Sync",
    "Market Indices Sync"
  ].freeze

  def perform
    CRITICAL_SYNCS.each { |task_name| check(task_name) }
  end

  private

  def check(task_name)
    logs = SystemLog.where(task_name: task_name)
                    .where("created_at > ?", LOOKBACK_WINDOW.ago)

    last_success = logs.where(severity: :success).order(created_at: :desc).first
    last_error   = logs.where(severity: :error).order(created_at: :desc).first

    return if last_success.present? # recent success cures prior errors
    return if last_error.blank?     # no errors recorded — silent but not failing

    alert(task_name, last_error: last_error, last_success: last_success)
  end

  # Three readers, one dedup. Sentry is the maintainer's, the SystemLog row is
  # the record Registros can show, and the notification is the only one that
  # goes looking for the owner instead of waiting to be looked at.
  def alert(task_name, last_error:, last_success:)
    return if recently_alerted?(task_name)

    Sentry.capture_message(
      "Sync failing: #{task_name}",
      level: :warning,
      extra: {
        task_name: task_name,
        last_error_at: last_error.created_at,
        last_error_message: last_error.error_message,
        last_success_at: last_success&.created_at,
        lookback_window: LOOKBACK_WINDOW.inspect
      }
    )

    record(task_name, last_error: last_error, last_success: last_success)
    notify_owner(task_name, last_error: last_error)
    mark_alerted(task_name)
  rescue StandardError => e
    # Never let an observability sweep crash itself — log and move on so the
    # next hour's run still happens.
    Rails.logger.error("CheckSyncHealthJob: failed to alert on #{task_name}: #{e.class} #{e.message}")
  end

  # The individual errors are already in Registros; this row is the pattern
  # over them, which is what the notification points back to.
  def record(task_name, last_error:, last_success:)
    SystemLog.create!(
      task_name: task_name,
      module_name: "health",
      severity: :error,
      error_message: "Sin sincronización exitosa desde #{last_success&.created_at&.to_date || 'hace más de 25 h'}. " \
                     "Último error: #{last_error.error_message}"
    )
  end

  # One account per instance by design (ADR-0010), so the first user is the
  # owner. No user at all means setup never ran and there is nobody to tell.
  def notify_owner(task_name, last_error:)
    owner = User.first
    return if owner.nil?

    Notifications::UseCases::CreateNotification.call(
      user_id: owner.id,
      title: OWNER_FACING.fetch(task_name, task_name),
      body: "#{last_error.error_message}. Revisa Registros para el detalle.",
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
