module Trading
  class TradeUpdated < BaseEvent
    attribute :trade_id, Types::Integer
    attribute :user_id, Types::Integer
    attribute :position_id, Types::Integer
    attribute :changes, Types::Hash
  end
end
