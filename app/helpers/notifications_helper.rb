module NotificationsHelper
  def notification_icon(notification)
    case notification.notification_type
    when "alert_triggered" then "bolt"
    when "earnings_reminder" then "calendar_today"
    when "system" then "settings"
    else "notifications"
    end
  end

  def notification_icon_style(notification)
    if notification.read?
      "bg-slate-100 dark:bg-slate-700 text-slate-400 dark:text-slate-500"
    else
      case notification.notification_type
      when "alert_triggered" then "bg-amber-100 text-amber-600"
      when "earnings_reminder" then "bg-blue-100 text-blue-600"
      when "system" then "bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300"
      else "bg-slate-100 text-slate-500"
      end
    end
  end
end
