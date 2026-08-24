module NavigationHelper
  # The four destinations of the 2.0 shell. Paths are English (ADR-011); two of
  # them still point at the screens their slice has not rewritten yet.
  MAIN_NAV = [
    { key: "panorama", icon: "grid_view",     path: :dashboard_path, controllers: %w[dashboard] },
    { key: "activos",  icon: "trending_up",   path: :portfolio_path, controllers: %w[portfolios trades positions watchlist_items market search earnings news] },
    { key: "reglas",   icon: "notifications", path: :alerts_path,    controllers: %w[alerts notifications] },
    { key: "ajustes",  icon: "settings",      path: :profile_path,   controllers: %w[profiles] }
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
