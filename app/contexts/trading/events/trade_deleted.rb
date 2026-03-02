module Trading
  module Events
    class TradeDeleted < BaseEvent
      attribute :trade_id, Types::Integer
      attribute :user_id, Types::Integer
      attribute :position_id, Types::Integer
    end
  end
end
