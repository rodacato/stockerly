module Alerts
  module UseCases
    class EvaluateRules < SimpleUseCase
      def call(asset_id:, new_price:, old_price: nil)
        asset = Asset.find_by(id: asset_id)
        return [] unless asset

        # Use a proxy with old_price so AlertEvaluator sees the pre-update price
        evaluator_asset = old_price ? AssetPriceProxy.new(asset, BigDecimal(old_price)) : asset

        rules = AlertRule.where(asset_symbol: asset.symbol, status: :active)
        triggered = Domain::AlertEvaluator.evaluate(rules, evaluator_asset, BigDecimal(new_price))

        triggered.each { |rule| publish_triggered(rule, new_price, evaluator_asset) }

        triggered
      end

      # Lightweight decorator so AlertEvaluator sees the pre-update price
      AssetPriceProxy = Struct.new(:asset, :current_price) do
        def method_missing(method, ...)
          asset.send(method, ...)
        end

        def respond_to_missing?(method, include_private = false)
          asset.respond_to?(method, include_private)
        end
      end

      private

      def publish_triggered(rule, price, asset)
        EventBus.publish(Events::AlertRuleTriggered.new(
          alert_rule_id: rule.id,
          user_id: rule.user_id,
          asset_symbol: rule.asset_symbol,
          triggered_price: price.to_s,
          context: trigger_context(rule, asset, price)
        ))
      end

      def trigger_context(rule, asset, price)
        return {} unless rule.condition == "day_change_percent"

        change = Domain::AlertEvaluator.day_change(asset, BigDecimal(price.to_s))
        change ? { day_change: change.to_s } : {}
      end
    end
  end
end
