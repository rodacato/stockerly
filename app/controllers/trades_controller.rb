class TradesController < AuthenticatedController
  FLASH_PARTIAL = "shared/flash_message"

  # D11: a real page first. The drawer is a presentation the JS layer adds; if
  # it never runs, this still works.
  def new
    @side = params[:side] == "sell" ? "sell" : "buy"
    @symbol = params[:symbol]
    @currency = current_user.preferred_currency
    @held = held_position
  end

  def create
    result = Trading::UseCases::ExecuteTrade.call(user: current_user, params: trade_params.to_h)

    case result
    in Dry::Monads::Success(trade)
      # Two destinations (D11's "Guardar y registrar otro"). Saving alone
      # targets _top, so the response navigates and the sheet goes with it;
      # saving-and-another stays in the frame and comes back empty, because
      # the point is entering the next movement without re-opening anything.
      if params[:and_another].present?
        render_another(trade)
      else
        redirect_to assets_path, notice: trade_notice(trade)
      end
    in Dry::Monads::Failure[ :validation, errors ]
      respond_with_alert(errors.values.flatten.first, fallback: assets_path)
    in Dry::Monads::Failure[ :insufficient_shares, message ]
      respond_with_alert(message, fallback: assets_path)
    in Dry::Monads::Failure[ _, message ]
      redirect_to assets_path, alert: message
    end
  end

  def edit
    return unless (trade = find_trade_or_redirect)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(trade, partial: "trades/edit_row", locals: { trade: trade }) }
      format.html { redirect_to positions_path }
    end
  end

  # Inline delete-confirm row replaces the trade row when the user clicks
  # delete. Lets the destroy action run without a JS confirm() dialog,
  # which is hostile on mobile and inconsistent with the Stockerly-2.0
  # design language.
  def confirm_destroy
    return unless (trade = find_trade_or_redirect)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(trade, partial: "trades/confirm_delete_row", locals: { trade: trade }) }
      format.html { redirect_to positions_path }
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
            flash_stream("notice", t("trades.flash.actualizado"))
          ]
        end
        format.html { redirect_to positions_path, notice: t("trades.flash.actualizado") }
      end
    in Dry::Monads::Failure[ :validation, errors ]
      respond_with_alert(errors.values.flatten.first, fallback: positions_path)
    in Dry::Monads::Failure[ _, message ]
      respond_with_alert(message, fallback: positions_path)
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
            flash_stream("notice", t("trades.flash.eliminado"))
          ]
        end
        format.html { redirect_to positions_path, notice: t("trades.flash.eliminado") }
      end
    in Dry::Monads::Failure[ _, message ]
      respond_with_alert(message, fallback: positions_path)
    end
  end

  private

  # What the average-cost projection anchors on (#428). Only a buy into a
  # position that already exists has an average to move, and only the symbol the
  # sheet was opened with — the field is free text, so the JS drops the
  # projection the moment it stops matching.
  def held_position
    return nil unless @side == "buy" && @symbol.present?

    asset = Asset.find_by(symbol: @symbol.upcase)
    return nil if asset.nil? || asset.asset_type_fixed_income?

    current_user.portfolio&.open_positions&.find_by(asset_id: asset.id)
  end

  # Six call sites differed only in the message and the non-Turbo fallback.
  def respond_with_alert(message, fallback:)
    respond_to do |format|
      format.turbo_stream { render turbo_stream: flash_stream("alert", message) }
      format.html { redirect_to fallback, alert: message }
    end
  end

  def flash_stream(type, message)
    turbo_stream.prepend("flash_messages", partial: FLASH_PARTIAL,
                         locals: { type: type, message: message })
  end

  def find_trade_or_redirect
    trade = current_user.portfolio&.trades&.find_by(id: params[:id])
    redirect_to positions_path, alert: t("trades.flash.no_encontrado") if trade.nil?
    trade
  end

  def trade_notice(trade)
    t("trades.flash.registrado",
      side: t("trades.flash.side_#{trade.buy? ? "compra" : "venta"}"),
      shares: trade.shares, symbol: trade.asset.symbol)
  end

  # A fresh sheet inside the frame, keeping the side the user was working in —
  # someone recording several sells is not switching back to buy each time.
  def render_another(trade)
    @side = trade.side
    @symbol = nil
    @currency = current_user.preferred_currency
    @saved_notice = trade_notice(trade)

    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace("trade_sheet", template: "trades/new") }
      format.html { redirect_to new_trade_path(side: trade.side), notice: @saved_notice }
    end
  end

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
