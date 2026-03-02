module Trading
  class PositionClosed < BaseEvent
    attribute :position_id, Types::Integer
    attribute :portfolio_id, Types::Integer
    attribute :asset_symbol, Types::String
  end
end
