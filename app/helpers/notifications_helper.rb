module NotificationsHelper
  # A helper rather than a before_action so a partial can ask for the count
  # without every request paying for it, navbar or not (mailers, error pages).
  def navbar_unread_count
    return 0 unless current_user
    @navbar_unread_count ||= current_user.notifications.unread.count
  end

  def notification_icon(notification)
    case notification.notification_type
    when "alert_triggered"   then "notifications_active"
    when "earnings_reminder" then "event"
    when "maturity_reminder" then "event_available"
    when "system"            then "info"
    else "notifications"
    end
  end

  # One tint per notification_type, matching `reglas-bandeja`. It used to be
  # two families, which put a CETES maturity and a rule firing in the same
  # colour — the collapse the inbox filter made everywhere else.
  ICON_STYLES = {
    "alert_triggered"   => "bg-primary-muted text-primary",
    "earnings_reminder" => "bg-bg-muted text-fg-subtle",
    "maturity_reminder" => "bg-warning-bg text-warning-fg",
    "system"            => "bg-bg-muted text-fg-subtle"
  }.freeze

  def notification_icon_style(notification)
    ICON_STYLES.fetch(notification.notification_type, "bg-bg-muted text-fg-subtle")
  end

  # One group per day, newest first. The owner reads weekly, so collapsing
  # everything before yesterday into one bucket would hide the dates he reads by.
  def group_notifications_by_date(notifications)
    notifications.group_by { |n| n.created_at.to_date }.map do |date, notices|
      [ notification_day_heading(date), notices ]
    end
  end

  def notification_day_heading(date)
    return "Hoy" if date == Date.current
    return "Ayer" if date == Date.current - 1

    format_date_header(date)
  end

  def format_date_header(date)
    weekday = DatetimeEsHelper::WEEKDAYS_ES[date.wday]
    format = date.year == Date.current.year ? :day_month_upper : :day_month_year_upper
    "#{weekday} #{l(date, format: format)}"
  end

  def format_notification_time(notification)
    d = notification.created_at.to_date
    if d == Date.current
      "hace #{time_ago_in_words(notification.created_at)} · #{notification.created_at.in_time_zone('America/Mexico_City').strftime('%H:%M')} CDMX"
    elsif d == Date.current - 1
      "ayer · #{notification.created_at.in_time_zone('America/Mexico_City').strftime('%H:%M')} CDMX"
    else
      "#{absolute_stamp(notification.created_at)} CDMX"
    end
  end
end
