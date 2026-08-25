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

  # One tint per notification_type, matching `reglas-bandeja`. It used to be
  # two families, which put a CETES maturity and a rule firing in the same
  # colour — the collapse the inbox filter made everywhere else.
  ICON_STYLES = {
    "alert_triggered"   => "bg-primary/10 text-primary",
    "earnings_reminder" => "bg-bg-muted text-fg-subtle",
    "maturity_reminder" => "bg-warning/10 text-warning",
    "system"            => "bg-bg-muted text-fg-subtle"
  }.freeze

  def notification_icon_style(notification)
    ICON_STYLES.fetch(notification.notification_type, "bg-bg-muted text-fg-subtle")
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
      # strftime("%b") is English regardless of locale, so an older notice read
      # "23 Aug 2026" on an es-MX screen. MONTHS_ES is what the date headers
      # above this row already use.
      date = notification.created_at.in_time_zone("America/Mexico_City")
      month = DatetimeEsHelper::MONTHS_ES[date.month - 1]
      "#{date.day} #{month} #{date.year} · #{date.strftime('%H:%M')} CDMX"
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
