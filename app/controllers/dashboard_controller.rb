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
      @upcoming_maturities = data[:upcoming_maturities]
      @cetes_summary   = data[:cetes_summary]
      @currency        = data[:currency]
      @market_status   = { us: MarketHours.us_market_open?, bmv: MarketHours.bmv_market_open?, crypto: true }
    end
  end

  def news_feed
    @news = MarketData::Queries::RecentNews.call
    render layout: false
  end

  def trending
    @trending = MarketData::Queries::TrendingAssets.call(limit: 5)
    render layout: false
  end

  # Notable Observations — JTBD #6, #40.
  # Filtered to assets the user holds (open positions) OR watches.
  # Per ADR-002, this Trading-side controller reads MarketData state
  # (TechnicalObservation) via its public model API; the filter joins
  # on user-owned associations (positions, watchlist_items).
  def notable_observations
    asset_ids = (
      current_user.watchlist_items.pluck(:asset_id) +
      current_user.portfolio&.positions&.where(status: :open)&.pluck(:asset_id).to_a
    ).uniq

    @observations = if asset_ids.any?
      TechnicalObservation.for_assets(asset_ids)
                          .within_last(14)
                          .recent
                          .includes(:asset)
                          .limit(10)
    else
      TechnicalObservation.none
    end

    render layout: false
  end
end
