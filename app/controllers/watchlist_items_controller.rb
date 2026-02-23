class WatchlistItemsController < AuthenticatedController
  def create
    result = Watchlist::AddAsset.call(user: current_user, asset_id: params[:asset_id])

    case result
    in Dry::Monads::Success(item)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.prepend("watchlist_items", partial: "watchlist_items/watchlist_item", locals: { item: item }) }
        format.html { redirect_back fallback_location: dashboard_path, notice: "Added to watchlist." }
      end
    in Dry::Monads::Failure[ :validation, errors ]
      redirect_back fallback_location: market_path, alert: errors.values.flatten.first
    in Dry::Monads::Failure[ :not_found, message ]
      redirect_back fallback_location: market_path, alert: message
    end
  end

  def destroy
    result = Watchlist::RemoveAsset.call(user: current_user, watchlist_item_id: params[:id])

    case result
    in Dry::Monads::Success(item)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(item) }
        format.html { redirect_back fallback_location: profile_path, notice: "Removed from watchlist." }
      end
    in Dry::Monads::Failure
      redirect_back fallback_location: profile_path, alert: "Item not found."
    end
  end
end
