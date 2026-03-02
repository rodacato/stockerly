class DashboardController < AuthenticatedController
  def show
    result = Trading::AssembleDashboard.call(user: current_user)

    if result.success?
      data = result.value!
      @summary         = data[:summary]
      @watchlist_items = data[:watchlist_items]
      @news            = data[:news]
      @trending        = data[:trending]
      @indices         = data[:indices]
      @sentiment       = data[:sentiment]
      @fear_greed      = data[:fear_greed]
      @weekly_insight  = data[:weekly_insight]
      @market_status   = { us: MarketHours.us_market_open?, bmv: MarketHours.bmv_market_open?, crypto: true }
    end
  end
end
