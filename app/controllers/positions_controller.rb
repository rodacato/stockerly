class PositionsController < AuthenticatedController
  # Historial: the trade log, the dividends received and what closed positions
  # made — the three lists D43 found had no other home. `/trades` used to hold
  # the first of them behind no inbound link at all; D60 folded it in here.
  def index
    case Trading::UseCases::AssembleHistorial.call(user: current_user)
    in Dry::Monads::Success(data)
      @currency  = data[:currency]
      @trades    = data[:trades]
      @dividends = data[:dividends]
      @closed    = data[:closed]
    in Dry::Monads::Failure[ :not_found, _ ]
      redirect_to portfolio_path, alert: t(".sin_cartera")
    end
  end
end
