module Alerts
  class EvaluateSentimentRules < ApplicationUseCase
    SYMBOL_MAP = {
      "crypto" => "FG_CRYPTO",
      "stocks" => "FG_STOCKS"
    }.freeze

    def call(index_type:, value:)
      symbol = SYMBOL_MAP[index_type]
      return Failure([ :invalid_index_type, "Unknown index type: #{index_type}" ]) unless symbol

      rules = AlertRule.where(
        asset_symbol: symbol,
        condition: [ :sentiment_above, :sentiment_below ],
        status: :active
      )

      triggered = AlertEvaluator.evaluate_sentiment(rules, value)

      triggered.each do |rule|
        publish_triggered(rule, value)
        rule.update!(status: :paused)
      end

      Success(triggered)
    end

    private

    def publish_triggered(rule, value)
      EventBus.publish(AlertRuleTriggered.new(
        alert_rule_id: rule.id,
        user_id: rule.user_id,
        asset_symbol: rule.asset_symbol,
        triggered_price: value.to_s
      ))
    end
  end
end
