class AlertsController < AuthenticatedController
  ALERT_RULE_PARTIAL = "alerts/alert_rule"

  def index
    data = Alerts::UseCases::LoadDashboard.call(user: current_user, filter: params[:filter])

    @rules           = data[:rules]
    @events          = data[:events]
    @preference      = data[:preference]
    @triggered_today = data[:triggered_today]
    @counts          = data[:counts]
    @filter          = data[:filter]
    @suggestions     = data[:suggestions]
  end

  # D14: the rule form is a route rendered into a frame and presented as a
  # sheet — the shape /trades/new settled in slice 2b.
  def new
    # The asset detail's "Crear regla" arrives with a symbol; /alerts does not.
    # A suggestion from the empty state arrives with the whole shape (ALR-2).
    @rule = AlertRule.new(condition: prefill_condition,
                          cooldown_minutes: AlertRule::DEFAULT_COOLDOWN_MINUTES,
                          asset_symbol: params[:asset_symbol].presence&.upcase,
                          threshold_value: params[:threshold_value].presence,
                          window_days: params[:window_days].presence)
  end

  def create
    result = Alerts::UseCases::CreateRule.call(user: current_user, params: alert_params.to_h)

    case result
    in Dry::Monads::Success(rule)
      respond_to do |format|
        format.turbo_stream { render turbo_stream: turbo_stream.prepend("alert_rules", partial: ALERT_RULE_PARTIAL, locals: { rule: rule }) }
        format.html { redirect_to alerts_path, notice: t("alerts.flash.creada") }
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
        format.html { redirect_to alerts_path, notice: t("alerts.flash.actualizada") }
      end
    in Dry::Monads::Failure[ :not_found, _message ]
      redirect_to alerts_path, alert: t("alerts.flash.no_encontrada")
    in Dry::Monads::Failure[ :validation, errors ]
      redirect_to alerts_path, alert: errors.values.flatten.first
    end
  end

  def toggle
    rule = Alerts::UseCases::ToggleRule.call(user: current_user, rule_id: params[:id])
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.replace(rule, partial: ALERT_RULE_PARTIAL, locals: { rule: rule }) }
      format.html { redirect_to alerts_path, notice: rule.active? ? t("alerts.flash.activada") : t("alerts.flash.pausada") }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to alerts_path, alert: t("alerts.flash.no_encontrada")
  end

  def destroy
    rule = Alerts::UseCases::DestroyRule.call(user: current_user, rule_id: params[:id])
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(rule) }
      format.html { redirect_to alerts_path, notice: t("alerts.flash.eliminada") }
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to alerts_path, alert: t("alerts.flash.no_encontrada")
  end

  private

  def alert_params
    params.expect(alert: [ :asset_symbol, :condition, :threshold_value, :window_days ])
  end

  # A condition that is not in the enum falls back rather than raising, so a
  # hand-edited link cannot 500 the form.
  def prefill_condition
    AlertRule.conditions.key?(params[:condition].to_s) ? params[:condition] : :price_crosses_above
  end
end
