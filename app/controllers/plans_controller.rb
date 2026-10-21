class PlansController < AuthenticatedController
  def show
    @plan = current_user.portfolio&.plan
    @values = form_values(@plan)
  end

  def update
    portfolio = current_user.portfolio
    return redirect_to settings_path unless portfolio

    case Trading::UseCases::SavePlan.call(portfolio: portfolio, params: plan_params.to_h)
    in Dry::Monads::Success
      redirect_to plan_path, notice: t("plans.flash.guardado")
    in Dry::Monads::Failure[ :validation, errors ]
      @plan = portfolio.plan
      @values = plan_params.to_h
      @errors = errors
      render :show, status: :unprocessable_content
    end
  end

  private

  def plan_params
    params.expect(plan: [ :stocks_share, :crypto_share, :fixed_income_share, :monthly_contribution ])
  end

  def form_values(plan)
    return {} unless plan

    plan.attributes.slice("stocks_share", "crypto_share", "fixed_income_share")
        .merge("monthly_contribution" => plan.monthly_contribution.to_i)
  end
end
