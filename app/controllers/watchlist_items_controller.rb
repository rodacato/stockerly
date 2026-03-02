class WatchlistItemsController < AuthenticatedController
  def create
    result = Trading::AddToWatchlist.call(user: current_user, asset_id: params[:asset_id])

    case result
    in Dry::Monads::Success(item)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("watchlist_button_#{item.asset_id}",
              html: helpers.turbo_frame_tag("watchlist_button_#{item.asset_id}") do
                helpers.content_tag(:span, class: "inline-flex items-center gap-1 text-emerald-500 text-xs font-medium") do
                  helpers.content_tag(:span, "check_circle", class: "material-symbols-outlined text-lg")
                end
              end),
            turbo_stream.prepend("flash_messages",
              partial: "shared/flash_message", locals: { type: "notice", message: "Added to watchlist." })
          ]
        end
        format.html { redirect_back fallback_location: dashboard_path, notice: "Added to watchlist." }
      end
    in Dry::Monads::Failure[ :validation, errors ]
      message = errors.values.flatten.first
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: "shared/flash_message", locals: { type: "alert", message: message })
        end
        format.html { redirect_back fallback_location: market_path, alert: message }
      end
    in Dry::Monads::Failure[ :not_found, message ]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: "shared/flash_message", locals: { type: "alert", message: message })
        end
        format.html { redirect_back fallback_location: market_path, alert: message }
      end
    end
  end

  def destroy
    result = Trading::RemoveFromWatchlist.call(user: current_user, watchlist_item_id: params[:id])

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
