module Alerts
  module UseCases
    # Runs once a day to evaluate calendar-driven alert rules (e.g.
    # dividend_ex_date). Publishes AlertRuleTriggered for each rule that
    # matches today's window so the existing handlers can record an event
    # and create a notification.
    class EvaluateDateBasedRules < ApplicationUseCase
      def call(today: Date.current)
        rules = AlertRule.date_based.where(status: :active)
        results = Domain::DateBasedAlertEvaluator.evaluate(rules, today: today)

        results.each { |r| publish_triggered(r) }

        Success(results)
      end

      private

      def publish_triggered(result)
        EventBus.publish(Events::AlertRuleTriggered.new(
          alert_rule_id: result.rule.id,
          user_id: result.rule.user_id,
          asset_symbol: result.rule.asset_symbol.to_s,
          triggered_price: result.event_date.to_s,
          context: result.context || {}
        ))
      end
    end
  end
end
