class AlertsController < AuthenticatedController
  ALERT_RULE_PARTIAL = "alerts/alert_rule"
  RULE_NOT_FOUND_MESSAGE = "Regla de alerta no encontrada."

  def index
    result = Alerts::UseCases::LoadDashboard.call(user: current_user, filter: params[:filter])
    data = result.value!

    @rules           = data[:rules]
    @events          = data[:events]
    @preference      = data[:preference]
    @triggered_today = data[:triggered_today]
    @counts          = data[:counts]
    @filter          = data[:filter]
  end

  def create
    result = Alerts::UseCases::CreateRule.call(user: current_user, params: alert_params.to_h)

    case result
    in Dry::Monads::Success(rule)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.prepend("alert_rules", partial: ALERT_RULE_PARTIAL, locals: { rule: rule }) }
        format.html { redirect_to alerts_path, notice: "Alerta creada." }
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
        format.turbo_stream { render turbo_stream: turbo_stream.replace(rule, partial: ALERT_RULE_PARTIAL, locals: { rule: rule }) }
        format.html { redirect_to alerts_path, notice: "Alerta actualizada." }
      end
    in Dry::Monads::Failure[ :not_found, _message ]
      redirect_to alerts_path, alert: RULE_NOT_FOUND_MESSAGE
    in Dry::Monads::Failure[ :validation, errors ]
      redirect_to alerts_path, alert: errors.values.flatten.first
    end
  end

  def toggle
    rule = Alerts::UseCases::ToggleRule.call(user: current_user, rule_id: params[:id])
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(rule, partial: ALERT_RULE_PARTIAL, locals: { rule: rule }) }
      format.html { redirect_to alerts_path, notice: rule.active? ? "Alerta activada." : "Alerta pausada." }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to alerts_path, alert: RULE_NOT_FOUND_MESSAGE
  end

  def destroy
    rule = Alerts::UseCases::DestroyRule.call(user: current_user, rule_id: params[:id])
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(rule) }
      format.html { redirect_to alerts_path, notice: "Alerta eliminada." }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to alerts_path, alert: RULE_NOT_FOUND_MESSAGE
  end

  private

  def alert_params
    params.require(:alert).permit(:asset_symbol, :condition, :threshold_value, :window_days)
  end
end
