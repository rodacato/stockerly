class TradesController < AuthenticatedController
  FLASH_PARTIAL = "shared/flash_message"

  # Filter params accepted on /trades:
  #   tipo:    "todos" | "compras" | "ventas"
  #   mercado: "todos" | "mxn" | "usd"
  #   anio:    "todos" | "<YYYY>"
  # Filters apply server-side via scopes on the trades collection. Counts
  # are computed against the unfiltered relation so the chips can show
  # the full year list and an honest "shown / total" footer label.
  def index
    @tipo    = params[:tipo].presence    || "todos"
    @mercado = params[:mercado].presence || "todos"
    @anio    = params[:anio].presence    || "todos"

    base = current_user.portfolio&.trades&.kept&.includes(:asset, :position) || Trade.none
    @total_count = base.count
    # Aggregate year-extraction at the DB level so we don't pull every
    # executed_at timestamp into Ruby memory just to call `.uniq` on
    # year. EXTRACT runs once; the result set is tiny.
    @available_years = base.distinct.pluck(Arel.sql("EXTRACT(YEAR FROM executed_at)::int")).sort.reverse

    scope = base
    scope = scope.where(side: filter_side)         if filter_side
    scope = scope.where(currency: filter_currency) if filter_currency
    # Use a date-range comparison instead of EXTRACT(YEAR FROM ...) so
    # Postgres can hit the `index_trades_on_executed_at` index. `all_year`
    # generates the inclusive [Jan 1, Dec 31] range.
    scope = scope.where(executed_at: Time.zone.local(@anio.to_i).all_year) if @anio != "todos"

    # Materialize once: the view iterates the relation twice (table body
    # + summary helper). `.to_a` avoids a redundant COUNT for `@shown_count`
    # and a double-load of the rows.
    @trades = scope.recent.limit(50).to_a
    @shown_count = @trades.size
  end

  # D11: a real page first. The drawer is a presentation the JS layer adds; if
  # it never runs, this still works.
  def new
    @side = params[:side] == "sell" ? "sell" : "buy"
    @symbol = params[:symbol]
    @currency = current_user.preferred_currency
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
      format.html { redirect_to trades_path }
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
            flash_stream("notice", "Movimiento actualizado.")
          ]
        end
        format.html { redirect_to trades_path, notice: "Movimiento actualizado." }
      end
    in Dry::Monads::Failure[ :validation, errors ]
      respond_with_alert(errors.values.flatten.first, fallback: trades_path)
    in Dry::Monads::Failure[ _, message ]
      respond_with_alert(message, fallback: trades_path)
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
            flash_stream("notice", "Movimiento eliminado.")
          ]
        end
        format.html { redirect_to trades_path, notice: "Movimiento eliminado." }
      end
    in Dry::Monads::Failure[ _, message ]
      respond_with_alert(message, fallback: trades_path)
    end
  end

  private

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
    redirect_to trades_path, alert: "Movimiento no encontrado." if trade.nil?
    trade
  end

  def trade_notice(trade)
    "#{trade.buy? ? "Compra" : "Venta"} registrada: #{trade.shares} títulos de #{trade.asset.symbol}"
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

  def filter_side
    case @tipo
    when "compras" then :buy
    when "ventas"  then :sell
    else nil
    end
  end

  def filter_currency
    case @mercado
    when "mxn" then "MXN"
    when "usd" then "USD"
    else nil
    end
  end
end
