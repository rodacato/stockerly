class PositionsController < AuthenticatedController
  def update
    position = current_user.portfolio&.positions&.find_by(id: params[:id])

    if position.nil?
      redirect_to portfolio_path, alert: "Position not found."
      return
    end

    labels = parse_labels(params.dig(:position, :labels))

    if position.update(notes: params.dig(:position, :notes), labels: labels)
      redirect_to portfolio_path, notice: "Position updated."
    else
      redirect_to portfolio_path, alert: "Could not update position."
    end
  end

  private

  def parse_labels(raw)
    return [] if raw.blank?

    raw.split(",").map(&:strip).reject(&:blank?).uniq.first(10)
  end
end
