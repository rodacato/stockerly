class AlertMailer < ApplicationMailer
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
end
