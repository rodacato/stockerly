class TradesController < AuthenticatedController
  def index
    @trades = current_user.portfolio&.trades&.kept&.recent&.includes(:asset, :position)&.limit(50) || []
  end

  def create
    result = Trading::UseCases::ExecuteTrade.call(user: current_user, params: trade_params.to_h)

    case result
    in Dry::Monads::Success(trade)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("trade_history", partial: "trades/trade_row", locals: { trade: trade }),
            turbo_stream.prepend("flash_messages", partial: "shared/flash_message",
              locals: { type: "notice", message: "#{trade.side.capitalize} executed: #{trade.shares.to_i} shares of #{trade.asset.symbol}" })
          ]
        end
        format.html { redirect_to portfolio_path, notice: "Trade executed successfully." }
      end
    in Dry::Monads::Failure[ :validation, errors ]
      error_msg = errors.values.flatten.first
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: "shared/flash_message", locals: { type: "alert", message: error_msg })
        end
        format.html { redirect_to portfolio_path, alert: error_msg }
      end
    in Dry::Monads::Failure[ :insufficient_shares, message ]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: "shared/flash_message", locals: { type: "alert", message: message })
        end
        format.html { redirect_to portfolio_path, alert: message }
      end
    in Dry::Monads::Failure[ _, message ]
      redirect_to portfolio_path, alert: message
    end
  end

  def edit
    trade = current_user.portfolio&.trades&.find_by(id: params[:id])

    if trade.nil?
      redirect_to trades_path, alert: "Trade not found."
      return
    end

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(trade, partial: "trades/edit_row", locals: { trade: trade }) }
      format.html { redirect_to trades_path }
    end
  end

  def update
    result = Trading::UseCases::UpdateTrade.call(
      user: current_user,
      params: update_trade_params.to_h.merge(trade_id: params[:id].to_i)
    )

    case result
    in Dry::Monads::Success(trade)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(trade, partial: "trades/trade_row", locals: { trade: trade }),
            turbo_stream.prepend("flash_messages", partial: "shared/flash_message",
              locals: { type: "notice", message: "Trade updated successfully." })
          ]
        end
        format.html { redirect_to trades_path, notice: "Trade updated successfully." }
      end
    in Dry::Monads::Failure[ :validation, errors ]
      error_msg = errors.values.flatten.first
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: "shared/flash_message", locals: { type: "alert", message: error_msg })
        end
        format.html { redirect_to trades_path, alert: error_msg }
      end
    in Dry::Monads::Failure[ _, message ]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: "shared/flash_message", locals: { type: "alert", message: message })
        end
        format.html { redirect_to trades_path, alert: message }
      end
    end
  end

  def destroy
    result = Trading::UseCases::DeleteTrade.call(user: current_user, trade_id: params[:id].to_i)

    case result
    in Dry::Monads::Success(trade)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.remove(trade),
            turbo_stream.prepend("flash_messages", partial: "shared/flash_message",
              locals: { type: "notice", message: "Trade deleted." })
          ]
        end
        format.html { redirect_to trades_path, notice: "Trade deleted." }
      end
    in Dry::Monads::Failure[ _, message ]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: "shared/flash_message", locals: { type: "alert", message: message })
        end
        format.html { redirect_to trades_path, alert: message }
      end
    end
  end

  private

  def trade_params
    params.require(:trade).permit(:asset_symbol, :side, :shares, :price_per_share, :fee, :executed_at)
  end

  def update_trade_params
    params.require(:trade).permit(:shares, :price_per_share, :fee, :executed_at)
  end
end
