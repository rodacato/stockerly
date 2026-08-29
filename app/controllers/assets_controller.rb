class AssetsController < AuthenticatedController
  rate_limit to: 10, within: 1.minute, only: [ :toggle_sync, :track ]
  rate_limit to: 15, within: 1.minute, only: :search_ticker

  def index
    data = Trading::UseCases::LoadAssets.call(user: current_user, tab: params[:tab])

    @tab             = data[:tab]
    @currency        = data[:currency]
    @portfolio       = data[:portfolio]
    @summary         = data[:summary]
    @positions       = data[:positions]
    @watchlist_items = data[:watchlist_items]
    @watchlist_gaps  = data[:watchlist_gaps]
    @sparkline_closes = data[:sparkline_closes]
    @day_changes     = data[:day_changes]
    @fx_unavailable  = data[:fx_unavailable]
  end

  def tracked
    data = Trading::UseCases::LoadTrackedAssets.call(user: current_user)

    @assets       = data[:assets]
    @held_ids     = data[:held_ids]
    @followed_ids = data[:followed_ids]
    @budget       = data[:budget]
  end

  def track
    result = Administration::UseCases::Assets::CreateAsset.call(admin: current_user, params: asset_params.to_h)

    case result
    in Dry::Monads::Success(asset)
      redirect_to tracked_assets_path, notice: t("assets.tracked.agregado", symbol: asset.symbol)
    in Dry::Monads::Failure[ _, errors ]
      redirect_to tracked_assets_path, alert: first_error(errors)
    end
  end

  def untrack
    result = Administration::UseCases::Assets::DeleteAsset.call(asset_id: params[:id], admin: current_user)

    case result
    in Dry::Monads::Success(symbol)
      redirect_to tracked_assets_path, notice: t("assets.tracked.eliminado", symbol: symbol)
    in Dry::Monads::Failure
      redirect_to tracked_assets_path, alert: t("assets.tracked.no_encontrado")
    end
  end

  def search_ticker
    result = Administration::UseCases::Assets::SearchTicker.call(query: params[:q])

    if result.success?
      render json: result.value!
    else
      render json: { error: result.failure.last }, status: :unprocessable_content
    end
  end

  def toggle_sync
    asset = Administration::UseCases::Assets::ToggleStatus.call(asset_id: params[:id])
    redirect_to tracked_assets_path,
                notice: t("assets.tracked.#{asset.active? ? "reanudado" : "pausado"}", symbol: asset.symbol)
  rescue ActiveRecord::RecordNotFound
    redirect_to tracked_assets_path, alert: t("assets.tracked.no_encontrado")
  end

  # The name a provider answers to, saved only if it answers. The use case does
  # the probing; a wrong mapping fails the sync on a name the owner believes is
  # right, so nothing is stored on faith.
  def map_source_symbol
    result = Administration::UseCases::Assets::MapProviderSymbol.call(
      asset_id: params[:id],
      provider: params[:provider].to_s,
      symbol: params[:symbol].to_s
    )

    case result
    in Dry::Monads::Success(asset)
      redirect_to tracked_assets_path, notice: t("assets.tracked.fuente_mapeada", symbol: asset.symbol)
    in Dry::Monads::Failure[ :unconfirmed, candidate ]
      redirect_to tracked_assets_path, alert: t("assets.tracked.fuente_no_reconoce", provider: params[:provider], symbol: candidate)
    in Dry::Monads::Failure[ _, _ ]
      redirect_to tracked_assets_path, alert: t("assets.tracked.fuente_no_mapeada")
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to tracked_assets_path, alert: t("assets.tracked.no_encontrado")
  end

  private

  def asset_params
    params.require(:asset).permit(:symbol, :name, :asset_type, :country, :exchange, :sector, :logo_url)
  end

  def first_error(errors)
    errors.is_a?(Hash) ? errors.values.flatten.first : errors
  end
end
