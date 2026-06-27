class WatchlistItemsController < AuthenticatedController
  FLASH_PARTIAL = "shared/flash_message"

  def create
    result = Trading::UseCases::AddToWatchlist.call(user: current_user, asset_id: params[:asset_id])

    case result
    in Dry::Monads::Success(item)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("watchlist_button_#{item.asset_id}",
              partial: "watchlist_items/watchlist_button", locals: { asset_id: item.asset_id }),
            turbo_stream.prepend("flash_messages",
              partial: FLASH_PARTIAL, locals: { type: "notice", message: "Agregado a tu watchlist." })
          ]
        end
        format.html { redirect_back fallback_location: dashboard_path, notice: "Agregado a tu watchlist." }
      end
    in Dry::Monads::Failure[ :validation, errors ]
      message = errors.values.flatten.first
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: FLASH_PARTIAL, locals: { type: "alert", message: message })
        end
        format.html { redirect_back fallback_location: market_path, alert: message }
      end
    in Dry::Monads::Failure[ :not_found, message ]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: FLASH_PARTIAL, locals: { type: "alert", message: message })
        end
        format.html { redirect_back fallback_location: market_path, alert: message }
      end
    end
  end

  def destroy
    item = Trading::UseCases::RemoveFromWatchlist.call(user: current_user, watchlist_item_id: params[:id])
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(item) }
      format.html { redirect_back fallback_location: profile_path, notice: "Eliminado de tu watchlist." }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_back fallback_location: profile_path, alert: "No encontramos ese elemento."
  end
end
