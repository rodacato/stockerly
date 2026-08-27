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
        format.html { redirect_back fallback_location: dashboard_path, notice: t("watchlist_items.flash.agregado") }
      end
    in Dry::Monads::Failure[ :validation, errors ]
      message = errors.values.flatten.first
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: FLASH_PARTIAL, locals: { type: "alert", message: message })
        end
        format.html { redirect_back fallback_location: assets_path, alert: message }
      end
    in Dry::Monads::Failure[ :not_found, message ]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: FLASH_PARTIAL, locals: { type: "alert", message: message })
        end
        format.html { redirect_back fallback_location: assets_path, alert: message }
      end
    end
  end

  def destroy
    item = Trading::UseCases::RemoveFromWatchlist.call(user: current_user, watchlist_item_id: params[:id])
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(item) }
      format.html { redirect_back fallback_location: profile_path, notice: t("watchlist_items.flash.eliminado") }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_back fallback_location: profile_path, alert: t("watchlist_items.flash.no_encontrado")
  end
end
