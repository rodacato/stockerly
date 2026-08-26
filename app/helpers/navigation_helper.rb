module NavigationHelper
  # The four destinations of the 2.0 shell. Paths are English (ADR-011).
  # `market` is the asset detail now — its listing, /search, /earnings and
  # /news were deleted with #295.
  MAIN_NAV = [
    { key: "panorama", icon: "grid_view",     path: :dashboard_path, controllers: %w[dashboard] },
    { key: "activos",  icon: "trending_up",   path: :assets_path,    controllers: %w[assets portfolios trades positions watchlist_items market] },
    { key: "reglas",   icon: "notifications", path: :alerts_path,    controllers: %w[alerts notifications] },
    { key: "ajustes",  icon: "settings",      path: :settings_path,  controllers: %w[settings profiles] }
  ].freeze

  def main_nav_items
    MAIN_NAV.map { |item| item.merge(href: send(item[:path]), active: nav_active?(item)) }
  end

  private

  # Matching on the controller rather than the exact path keeps a tab lit across
  # the screens it owns — /trades belongs to Activos even though the tab links
  # to /portfolio.
  def nav_active?(item)
    item[:controllers].include?(controller_path.sub(%r{\Aadmin/}, "")) ||
      (item[:key] == "ajustes" && controller_path.start_with?("admin/"))
  end
end
