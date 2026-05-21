module Alerts
  module Events
    class AlertRuleTriggered < BaseEvent
      attribute :alert_rule_id, Types::Integer
      attribute :user_id, Types::Integer
      attribute :asset_symbol, Types::String.optional.default { "" }
      attribute :triggered_price, Types::String

      # Optional payload for date-based rules (holiday_name, days_until, etc.).
      # Empty hash for price/RSI/volume rules. Keys are :symbol.
      attribute :context, Types::Hash.default { {} }
    end
  end
end
