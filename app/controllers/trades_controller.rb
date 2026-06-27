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

  def create
    result = Trading::UseCases::ExecuteTrade.call(user: current_user, params: trade_params.to_h)

    case result
    in Dry::Monads::Success(trade)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("trade_history", partial: "trades/trade_row", locals: { trade: trade }),
            turbo_stream.prepend("flash_messages", partial: FLASH_PARTIAL,
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
            partial: FLASH_PARTIAL, locals: { type: "alert", message: error_msg })
        end
        format.html { redirect_to portfolio_path, alert: error_msg }
      end
    in Dry::Monads::Failure[ :insufficient_shares, message ]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: FLASH_PARTIAL, locals: { type: "alert", message: message })
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

  # Inline delete-confirm row replaces the trade row when the user clicks
  # delete. Lets the destroy action run without a JS confirm() dialog,
  # which is hostile on mobile and inconsistent with the Stockerly-2.0
  # design language.
  def confirm_destroy
    trade = current_user.portfolio&.trades&.find_by(id: params[:id])

    if trade.nil?
      redirect_to trades_path, alert: "Movimiento no encontrado."
      return
    end

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
            turbo_stream.prepend("flash_messages", partial: FLASH_PARTIAL,
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
            partial: FLASH_PARTIAL, locals: { type: "alert", message: error_msg })
        end
        format.html { redirect_to trades_path, alert: error_msg }
      end
    in Dry::Monads::Failure[ _, message ]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: FLASH_PARTIAL, locals: { type: "alert", message: message })
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
            turbo_stream.prepend("flash_messages", partial: FLASH_PARTIAL,
              locals: { type: "notice", message: "Movimiento eliminado." })
          ]
        end
        format.html { redirect_to trades_path, notice: "Movimiento eliminado." }
      end
    in Dry::Monads::Failure[ _, message ]
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.prepend("flash_messages",
            partial: FLASH_PARTIAL, locals: { type: "alert", message: message })
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
