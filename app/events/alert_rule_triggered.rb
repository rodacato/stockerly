class AlertRuleTriggered < BaseEvent
  attribute :alert_rule_id, Types::Integer
  attribute :user_id, Types::Integer
  attribute :asset_symbol, Types::String
  attribute :triggered_price, Types::String
end
