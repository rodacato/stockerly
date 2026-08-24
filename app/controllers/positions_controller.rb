class PositionsController < AuthenticatedController
  # The position lists the Consolidado does not carry — open, closed, dividends
  # and the trade log. Routable with no nav entry, the same treatment /market,
  # /earnings and /news got in slice 1: the asset detail draws Operaciones and
  # Dividendos per asset, and its "Ver todas" is where a global list belongs.
  def index
    result = Trading::UseCases::LoadPortfolio.call(user: current_user, tab: params[:tab] || "open")

    if result.success?
      data = result.value!
      @portfolio          = data[:portfolio]
      @positions          = data[:positions]
      @summary            = data[:summary]
      @tab                = data[:tab]
      @upcoming_dividends = data[:upcoming_dividends]
      @currency           = data[:currency]
    else
      redirect_to portfolio_path, alert: "Portafolio no encontrado."
    end
  end

  def update
    position = current_user.portfolio&.positions&.find_by(id: params[:id])

    if position.nil?
      redirect_to positions_path, alert: "No encontramos la posición."
      return
    end

    labels = parse_labels(params.dig(:position, :labels))

    if position.update(notes: params.dig(:position, :notes), labels: labels)
      redirect_to positions_path, notice: "Actualizamos la posición."
    else
      redirect_to positions_path, alert: "No pudimos actualizar la posición."
    end
  end

  private

  def parse_labels(raw)
    return [] if raw.blank?

    raw.split(",").map(&:strip).reject(&:blank?).uniq.first(10)
  end
end
