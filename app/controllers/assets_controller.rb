class AssetsController < AuthenticatedController
  def index
    data = Trading::UseCases::LoadAssets.call(user: current_user, tab: params[:tab])

    @tab             = data[:tab]
    @currency        = data[:currency]
    @portfolio       = data[:portfolio]
    @summary         = data[:summary]
    @positions       = data[:positions]
    @watchlist_items = data[:watchlist_items]
    @fx_unavailable  = data[:fx_unavailable]
  end
end
