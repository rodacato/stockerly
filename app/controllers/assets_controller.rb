class AssetsController < AuthenticatedController
  rate_limit to: 10, within: 1.minute, only: :toggle_sync

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

  def tracked
    data = Trading::UseCases::LoadTrackedAssets.call(user: current_user)

    @assets       = data[:assets]
    @held_ids     = data[:held_ids]
    @followed_ids = data[:followed_ids]
    @budget       = data[:budget]
  end

  def toggle_sync
    asset = Administration::UseCases::Assets::ToggleStatus.call(asset_id: params[:id])
    redirect_to tracked_assets_path,
                notice: t("assets.tracked.#{asset.active? ? "reanudado" : "pausado"}", symbol: asset.symbol)
  rescue ActiveRecord::RecordNotFound
    redirect_to tracked_assets_path, alert: t("assets.tracked.no_encontrado")
  end
end
