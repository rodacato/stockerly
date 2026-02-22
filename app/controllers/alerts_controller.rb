class AlertsController < AuthenticatedController
  def index
    @rules = current_user.alert_rules.order(created_at: :desc)
    @events = current_user.alert_events.recent
    @preference = current_user.alert_preference
    @triggered_today = current_user.alert_events.where("triggered_at >= ?", Date.current.beginning_of_day).count
  end

  def create
    result = Alerts::CreateRule.call(user: current_user, params: alert_params.to_h)

    case result
    in Dry::Monads::Success(rule)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.prepend("alert_rules", partial: "alerts/alert_rule", locals: { rule: rule }) }
        format.html { redirect_to alerts_path, notice: "Alert created successfully." }
      end
    in Dry::Monads::Failure[:validation, errors]
      redirect_to alerts_path, alert: errors.values.flatten.first
    end
  end

  def update
    result = Alerts::UpdateRule.call(user: current_user, rule_id: params[:id], params: alert_params.to_h)

    case result
    in Dry::Monads::Success(rule)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(rule, partial: "alerts/alert_rule", locals: { rule: rule }) }
        format.html { redirect_to alerts_path, notice: "Alert updated successfully." }
      end
    in Dry::Monads::Failure[:not_found, message]
      redirect_to alerts_path, alert: message
    in Dry::Monads::Failure[:validation, errors]
      redirect_to alerts_path, alert: errors.values.flatten.first
    end
  end

  def toggle
    result = Alerts::ToggleRule.call(user: current_user, rule_id: params[:id])

    case result
    in Dry::Monads::Success(rule)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(rule, partial: "alerts/alert_rule", locals: { rule: rule }) }
        format.html { redirect_to alerts_path, notice: "Alert #{rule.active? ? 'activated' : 'paused'}." }
      end
    in Dry::Monads::Failure
      redirect_to alerts_path, alert: "Alert rule not found."
    end
  end

  def destroy
    result = Alerts::DestroyRule.call(user: current_user, rule_id: params[:id])

    case result
    in Dry::Monads::Success(rule)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.remove(rule) }
        format.html { redirect_to alerts_path, notice: "Alert deleted successfully." }
      end
    in Dry::Monads::Failure
      redirect_to alerts_path, alert: "Alert rule not found."
    end
  end

  private

  def alert_params
    params.require(:alert).permit(:asset_symbol, :condition, :threshold_value)
  end
end
