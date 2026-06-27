module Alerts
  module Events
    class RuleCreated < BaseEvent
      attribute :rule_id,      Types::Integer
      attribute :user_id,      Types::Integer
      attribute :asset_symbol, Types::String.optional
      attribute :condition,    Types::String
    end
  end
end
