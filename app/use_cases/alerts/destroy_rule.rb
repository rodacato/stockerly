module Alerts
  class DestroyRule < ApplicationUseCase
    def call(user:, rule_id:)
      rule = yield find_rule(user, rule_id)
      rule.destroy!

      Success(rule)
    end

    private

    def find_rule(user, id)
      rule = user.alert_rules.find_by(id: id)
      rule ? Success(rule) : Failure([:not_found, "Alert rule not found"])
    end
  end
end
