class AlertMailer < ApplicationMailer
  # D17: `email_notifications_enabled` was written by the settings screen and
  # read by nothing. It guards these two, which are notifications.
  #
  # Deliberately not on ApplicationMailer: UserMailer#password_reset is the way
  # back into an account, and a single-user instance with no support desk cannot
  # afford a switch that locks its owner out.
  after_action :respect_notification_setting

  # One email a day with everything the app noticed. Descriptive per ADR-0001:
  # it reports what happened, it does not suggest what to do about it.
  def daily_digest(user, notifications)
    @user = user
    @notifications = notifications

    mail(to: user.email, subject: "Tu resumen de hoy · #{pluralize_es(notifications.size, 'aviso', 'avisos')}")
  end

  # Sent the moment a rule fires, for users who asked to be interrupted.
  def urgent_alert(user, notification)
    @user = user
    @notification = notification

    mail(to: user.email, subject: notification.title)
  end

  private

  def pluralize_es(count, singular, plural)
    "#{count} #{count == 1 ? singular : plural}"
  end

  def respect_notification_setting
    return if SiteConfig.enabled?("email_notifications_enabled", default: true)

    mail.perform_deliveries = false
    Rails.logger.info("[AlertMailer] delivery skipped: email_notifications_enabled is off")
  end
end
