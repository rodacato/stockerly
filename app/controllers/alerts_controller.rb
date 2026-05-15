class AlertsController < AuthenticatedController
  def index
    result = Alerts::UseCases::LoadDashboard.call(user: current_user)
    data = result.value!

    @rules           = data[:rules]
    @events          = data[:events]
    @preference      = data[:preference]
    @triggered_today = data[:triggered_today]
  end

  def create
    result = Alerts::UseCases::CreateRule.call(user: current_user, params: alert_params.to_h)

    case result
    in Dry::Monads::Success(rule)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.prepend("alert_rules", partial: "alerts/alert_rule", locals: { rule: rule }) }
        format.html { redirect_to alerts_path, notice: "Alert created successfully." }
      end
    in Dry::Monads::Failure[ :validation, errors ]
      redirect_to alerts_path, alert: errors.values.flatten.first
    end
  end

  def update
    result = Alerts::UseCases::UpdateRule.call(user: current_user, rule_id: params[:id], params: alert_params.to_h)

    case result
    in Dry::Monads::Success(rule)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.replace(rule, partial: "alerts/alert_rule", locals: { rule: rule }) }
        format.html { redirect_to alerts_path, notice: "Alert updated successfully." }
      end
    in Dry::Monads::Failure[ :not_found, message ]
      redirect_to alerts_path, alert: message
    in Dry::Monads::Failure[ :validation, errors ]
      redirect_to alerts_path, alert: errors.values.flatten.first
    end
  end

  def toggle
    rule = Alerts::UseCases::ToggleRule.call(user: current_user, rule_id: params[:id])
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(rule, partial: "alerts/alert_rule", locals: { rule: rule }) }
      format.html { redirect_to alerts_path, notice: "Alert #{rule.active? ? 'activated' : 'paused'}." }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to alerts_path, alert: "Alert rule not found."
  end

  def destroy
    rule = Alerts::UseCases::DestroyRule.call(user: current_user, rule_id: params[:id])
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(rule) }
      format.html { redirect_to alerts_path, notice: "Alert deleted successfully." }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to alerts_path, alert: "Alert rule not found."
  end

  private

  def alert_params
    params.require(:alert).permit(:asset_symbol, :condition, :threshold_value)
  end
end
