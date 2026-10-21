class SendDailyDigestJob < ApplicationJob
  include SyncLogging

  queue_as :default

  def perform
    sent = Notifications::UseCases::SendDailyDigest.call

    log_sync_success("Daily Digest", message: I18n.t("notificaciones.registro.resumenes_enviados", count: sent))
  rescue StandardError => e
    log_sync_failure("Daily Digest", e.message)
    raise
  end
end
