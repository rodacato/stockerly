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
              locals: { type: "notice", message: "#{trade.buy? ? 'Compra' : 'Venta'} registrada: #{trade.shares} títulos de #{trade.asset.symbol}" })
          ]
        end
        format.html { redirect_to portfolio_path, notice: "Movimiento registrado." }
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
      redirect_to trades_path, alert: "Movimiento no encontrado."
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
              locals: { type: "notice", message: "Movimiento actualizado." })
          ]
        end
        format.html { redirect_to trades_path, notice: "Movimiento actualizado." }
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
              locals: { type: "notice", message: "Movimiento eliminado." })
          ]
        end
        format.html { redirect_to trades_path, notice: "Movimiento eliminado." }
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
    raw = params.require(:trade).permit(:asset_symbol, :side, :shares, :price_per_share, :fee, :executed_at, :currency, :fx_rate_at_execution).to_h
    # Treat empty strings from the form's optional selectors as "not provided"
    # so the contract's `optional(:currency).maybe(...)` rule applies and
    # ExecuteTrade falls back to the asset's native currency.
    raw["currency"] = nil if raw["currency"].blank?
    raw["fx_rate_at_execution"] = nil if raw["fx_rate_at_execution"].blank?
    raw
  end

  def update_trade_params
    params.require(:trade).permit(:shares, :price_per_share, :fee, :executed_at)
  end
end
