module ApplicationHelper
  include Pagy::Frontend

  def app_nav_active?(path)
    current_page?(path) ? "text-primary bg-primary/10" : "text-slate-600 dark:text-slate-300 hover:text-primary hover:bg-slate-50 dark:hover:bg-slate-800"
  end

  def admin_nav_active?(path)
    current_page?(path) ? "bg-primary text-white" : "text-slate-600 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white hover:bg-slate-50 dark:hover:bg-slate-800"
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
        label: "Market closed",
        dot_class: "bg-slate-300 dark:bg-slate-600",
        text_class: "text-slate-400 dark:text-slate-500"
      }
    end

    age = data_age_minutes(asset)

    if age < 2
      {
        state: :live,
        label: "Live",
        dot_class: "bg-emerald-500 animate-pulse",
        text_class: "text-emerald-600 dark:text-emerald-400"
      }
    elsif age < 15
      {
        state: :delayed,
        label: "Delayed",
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
    return "No data" if age_minutes == Float::INFINITY

    if age_minutes < 60
      "#{age_minutes.round}min ago"
    elsif age_minutes < 1440
      hours = (age_minutes / 60).round
      "#{hours}h ago"
    else
      days = (age_minutes / 1440).round
      "#{days}d ago"
    end
  end
end
