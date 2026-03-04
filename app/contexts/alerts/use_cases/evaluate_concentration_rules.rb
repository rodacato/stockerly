module Alerts
  module UseCases
    class EvaluateConcentrationRules < ApplicationUseCase
      def call(user:, hhi:)
        rules = AlertRule.where(
          user: user,
          asset_symbol: "PORTFOLIO",
          condition: :concentration_risk,
          status: :active
        )

        triggered = rules.select do |rule|
          rule.cooled_down? && hhi >= rule.threshold_value
        end

        triggered.each do |rule|
          rule.update!(last_triggered_at: Time.current)
          publish(Events::AlertRuleTriggered.new(
            alert_rule_id: rule.id,
            user_id: rule.user_id,
            asset_symbol: "PORTFOLIO",
            triggered_price: hhi.to_s
          ))
        end

        Success(triggered)
      end
    end
  end
end
