module Trading
  class TradeExecuted < BaseEvent
    attribute :trade_id, Types::Integer
    attribute :user_id, Types::Integer
    attribute :position_id, Types::Integer
    attribute :side, Types::String
    attribute :shares, Types::String
  end
end
