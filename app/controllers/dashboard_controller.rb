class DashboardController < AuthenticatedController
  def show
    result = Trading::UseCases::AssembleDashboard.call(user: current_user)

    if result.success?
      data = result.value!
      @summary         = data[:summary]
      @watchlist_items = data[:watchlist_items]
      @indices         = data[:indices]
      @sentiment       = data[:sentiment]
      @fear_greed      = data[:fear_greed]
      @weekly_insight  = data[:weekly_insight]
      @ai_insight      = data[:ai_insight]
      @market_status   = { us: MarketHours.us_market_open?, bmv: MarketHours.bmv_market_open?, crypto: true }
    end
  end

  def news_feed
    @news = NewsArticle.recent
    render layout: false
  end

  def trending
    @trending = Asset.where(asset_type: :stock)
                     .where.not(current_price: nil)
                     .where.not(change_percent_24h: nil)
                     .includes(:trend_scores)
                     .order(Arel.sql("ABS(change_percent_24h) DESC"))
                     .limit(5)
    render layout: false
  end
end
