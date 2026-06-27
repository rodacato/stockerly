module ApplicationHelper
  def app_nav_active?(path)
    current_page?(path) ? "text-primary bg-primary/10" : "text-slate-600 dark:text-slate-300 hover:text-primary hover:bg-slate-50 dark:hover:bg-slate-800"
  end

  def admin_nav_active?(path)
    current_page?(path) ? "bg-primary text-white" : "text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white hover:bg-slate-50 dark:hover:bg-slate-800"
  end

  # Renders a duration in es-MX human form: "2 horas", "1 hora", "30 minutos",
  # "24 horas". Avoids relying on Rails' `distance_of_time_in_words` since
  # the project does not yet have an es-MX locale wired (see issue #113).
  def duration_in_words_es(duration)
    seconds = duration.to_i
    if seconds % 1.hour.to_i == 0
      hours = seconds / 1.hour.to_i
      hours == 1 ? "1 hora" : "#{hours} horas"
    elsif seconds % 1.minute.to_i == 0
      minutes = seconds / 1.minute.to_i
      minutes == 1 ? "1 minuto" : "#{minutes} minutos"
    else
      "#{seconds} segundos"
    end
  end

  # Returns a hash describing the data freshness state for an asset.
  #
  # @param asset [Asset] the asset to check
  # @param market_open [Boolean] whether the asset's market is currently open
  # @return [Hash] with keys :state, :label, :dot_class, :text_class
  def combined_data_status(asset, market_open)
    unless market_open
      return {
        state: :closed,
        label: "Mercado cerrado",
        dot_class: "bg-slate-300 dark:bg-slate-600",
        text_class: "text-slate-400 dark:text-slate-500"
      }
    end

    age = data_age_minutes(asset)

    if age < 2
      {
        state: :live,
        label: "En vivo",
        dot_class: "bg-emerald-500 animate-pulse",
        text_class: "text-emerald-600 dark:text-emerald-400"
      }
    elsif age < 15
      {
        state: :delayed,
        label: "Retrasado",
        dot_class: "bg-amber-500",
        text_class: "text-amber-600 dark:text-amber-400"
      }
    else
      {
        state: :stale,
        label: stale_age_label(age),
        dot_class: "bg-amber-500",
        text_class: "text-amber-600 dark:text-amber-400",
        timestamp: asset.price_updated_at
      }
    end
  end

  # Determines if an asset's market is open based on the @market_status hash.
  def market_open_for(asset, market_status = nil)
    market_status ||= @market_status
    return MarketHours.open_for_asset?(asset) if market_status.nil?
    return true if asset.asset_type_crypto?
    return market_status[:bmv] if asset.country == "MX"

    market_status[:us]
  end

  private

  def data_age_minutes(asset)
    return Float::INFINITY if asset.price_updated_at.nil?
    ((Time.current - asset.price_updated_at) / 60.0).round(1)
  end

  def stale_age_label(age_minutes)
    return "Sin datos" if age_minutes == Float::INFINITY

    if age_minutes < 60
      "hace #{age_minutes.round}min"
    elsif age_minutes < 1440
      hours = (age_minutes / 60).round
      "hace #{hours}h"
    else
      days = (age_minutes / 1440).round
      "hace #{days}d"
    end
  end
end
