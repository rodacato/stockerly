module Trading
  module UseCases
    # Writes the owner's plan. There is one per portfolio, and nothing here
    # suggests a number: an empty plan stays empty until the owner fills it.
    class SavePlan < ApplicationUseCase
      def call(portfolio:, params:)
        attrs = yield validate(Contracts::SavePlanContract, params)
        plan = portfolio.plan || portfolio.build_plan

        if plan.update(attrs)
          Success(plan)
        else
          Failure([ :validation, plan.errors.to_hash ])
        end
      end
    end
  end
end
