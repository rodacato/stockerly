module Alerts
  class UpdateRule < ApplicationUseCase
    def call(user:, rule_id:, params:)
      rule  = yield find_rule(user, rule_id)
      attrs = yield validate(Alerts::CreateContract, params)
      _     = yield persist(rule, attrs)

      Success(rule)
    end

    private

    def find_rule(user, id)
      rule = user.alert_rules.find_by(id: id)
      rule ? Success(rule) : Failure([:not_found, "Alert rule not found"])
    end

    def persist(rule, attrs)
      rule.update!(
        asset_symbol: attrs[:asset_symbol].upcase,
        condition: attrs[:condition],
        threshold_value: attrs[:threshold_value]
      )
      Success(rule)
    rescue ActiveRecord::RecordInvalid => e
      Failure([:validation, e.record.errors.to_hash])
    end
  end
end
