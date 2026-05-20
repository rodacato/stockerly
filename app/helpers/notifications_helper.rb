module NotificationsHelper
  # Lazy-loaded for the navbar bell + dropdown. Helpers so partials avoid
  # reading instance variables that a base-controller before_action would
  # otherwise have to populate on every request, even when the navbar
  # isn't visible (mailers, error pages).
  def navbar_notifications
    return [] unless current_user
    @navbar_notifications ||= current_user.notifications.recent.limit(6).to_a
  end

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

  # Returns Tailwind classes for the icon tile background + foreground.
  # Two visual families per the inbox mockup: "alerta" (green tint, covers
  # alert_triggered + reminders) and "sistema" (primary tint).
  def notification_icon_style(notification)
    if notification.kind == "alerta"
      "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400"
    else
      "bg-primary/8 dark:bg-primary/15 text-primary"
    end
  end

  def notification_category_chip_classes(notification)
    if notification.kind == "alerta"
      "bg-emerald-50 dark:bg-emerald-900/20 text-emerald-600 dark:text-emerald-400"
    else
      "bg-primary/8 dark:bg-primary/15 text-primary"
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

  WEEKDAYS = %w[DOM LUN MAR MIÉ JUE VIE SÁB].freeze
  MONTHS   = %w[ENE FEB MAR ABR MAY JUN JUL AGO SEP OCT NOV DIC].freeze

  def format_date_header(date)
    "#{WEEKDAYS[date.wday]} #{date.day} #{MONTHS[date.month - 1]} #{date.year}"
  end

  def format_notification_time(notification)
    d = notification.created_at.to_date
    if d == Date.current
      "hace #{time_ago_in_words(notification.created_at)} · #{notification.created_at.in_time_zone('America/Mexico_City').strftime('%H:%M')} CDMX"
    elsif d == Date.current - 1
      "ayer · #{notification.created_at.in_time_zone('America/Mexico_City').strftime('%H:%M')} CDMX"
    else
      "#{notification.created_at.strftime('%-d %b %Y')} · #{notification.created_at.in_time_zone('America/Mexico_City').strftime('%H:%M')} CDMX"
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
    end
  end
end
