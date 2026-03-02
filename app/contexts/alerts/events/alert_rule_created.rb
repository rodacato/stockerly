module Alerts
  module Events
    class AlertRuleCreated < BaseEvent
      attribute :alert_rule_id, Types::Integer
      attribute :user_id, Types::Integer
      attribute :asset_symbol, Types::String
      attribute :condition, Types::String
    end
  end
end
