module SignalsHelper
  # The Señales list groups by the day the reading was observed: today,
  # yesterday, then one heading per date. Returns Array<[heading, rows]> in
  # display order. It resembles NotificationsHelper#group_notifications_by_date
  # and is deliberately not shared: the inbox collapses everything older than
  # yesterday into one bucket, and this screen does not.
  def group_signals_by_date(observations)
    observations.group_by { |o| o.observed_at.to_date }
                .sort_by { |date, _| -date.to_time.to_i }
                .map { |date, rows| [ signal_date_heading(date), rows ] }
  end

  def signal_date_heading(date)
    case date
    when Date.current     then t("signals.index.hoy")
    when Date.current - 1 then t("signals.index.ayer")
    else "#{DatetimeEsHelper::WEEKDAYS_ES[date.wday]} #{l(date, format: :day_month_upper)}"
    end
  end
end
