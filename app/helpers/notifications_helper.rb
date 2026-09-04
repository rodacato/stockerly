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

  def notification_category_chip_classes(notification)
    if notification.kind == "alerta"
      "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400"
    else
      "bg-primary-muted text-primary"
    end
  end

  def notification_category_label(notification)
    notification.kind == "alerta" ? "Alerta" : "Sistema"
  end

  # Buckets a relation of notifications into the inbox's date groups, in
  # display order. Returns an Array<[heading_string, Array<Notification>]>.
  # Headings follow the mockup: "Hoy · MIÉ 14 MAY 2026", "Ayer · ...",
  # "Más temprano · DD MMM YYYY y antes".
  def group_notifications_by_date(notifications)
    today     = Date.current
    yesterday = today - 1

    buckets = { today: [], yesterday: [], earlier: [] }
    notifications.each do |n|
      d = n.created_at.to_date
      if d == today
        buckets[:today] << n
      elsif d == yesterday
        buckets[:yesterday] << n
      else
        buckets[:earlier] << n
      end
    end

    out = []
    out << [ "Hoy · #{format_date_header(today)}",      buckets[:today] ]      if buckets[:today].any?
    out << [ "Ayer · #{format_date_header(yesterday)}", buckets[:yesterday] ] if buckets[:yesterday].any?
    if buckets[:earlier].any?
      first_date = buckets[:earlier].first.created_at.to_date
      out << [ "Más temprano · #{format_date_header(first_date)} y antes", buckets[:earlier] ]
    end
    out
  end

  def format_date_header(date)
    weekday = DatetimeEsHelper::WEEKDAYS_ES[date.wday]
    month   = DatetimeEsHelper::MONTHS_ES[date.month - 1]
    "#{weekday} #{date.day} #{month} #{date.year}"
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

  # Returns the asset symbol associated with the notification, or nil. The
  # inbox row links to /market/:symbol — the Asset record itself isn't
  # needed, so we read the symbol straight off the already-loaded notifiable
  # (preloaded by ListRecent) instead of per-row Asset.find_by hits.
  def notifiable_asset_symbol(notification)
    case notification.notifiable
    when AlertRule               then notification.notifiable.asset_symbol
    when EarningsEvent, Position then notification.notifiable.asset&.symbol
    else nil
    end
  end
end
