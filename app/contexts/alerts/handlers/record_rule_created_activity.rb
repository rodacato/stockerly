module Alerts
  module Handlers
    class RecordRuleCreatedActivity
      def self.call(event)
        user_id      = event.is_a?(Hash) ? event[:user_id] : event.user_id
        asset_symbol = event.is_a?(Hash) ? event[:asset_symbol] : event.asset_symbol
        condition    = event.is_a?(Hash) ? event[:condition] : event.condition

        ActivityRecorder.call(
          user:   User.find_by(id: user_id),
          action: "alert_rule_created",
          params: {
            asset_symbol: asset_symbol.to_s,
            condition:    condition.to_s
          }
        )
      end
    end
  end
end
