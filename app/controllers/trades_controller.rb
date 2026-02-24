class TradesController < AuthenticatedController
  def index
    @trades = current_user.portfolio&.trades&.recent&.includes(:asset, :position)&.limit(50) || []
  end

  def create
    result = Trading::ExecuteTrade.call(user: current_user, params: trade_params.to_h)

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

  private

  def trade_params
    params.require(:trade).permit(:asset_symbol, :side, :shares, :price_per_share, :fee, :executed_at)
  end
end
